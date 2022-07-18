//
//  ApplicationState.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 19.06.22.
//

import Foundation
import DataCapturing
import CoreMotion

class ApplicationState: ObservableObject {
    static let urlRegEx = "(https?:\\/\\/[^\\/]+)(\\.[^\\/]+)?(:\\d+)?(\\/.+)*\\/?"

    let settings: Settings
    let dcs: DataCapturingService
    var synchronizer: Synchronizer?
    @Published var hasAcceptedCurrentPrivacyPolicy: Bool
    var isLoggedIn: Bool
    @Published var hasValidServerURL: Bool
    @Published var hasFix: Bool
    @Published var tripDistance: Double
    @Published var duration: TimeInterval
    @Published var latitude: Double
    @Published var longitude: Double
    @Published var speed: Double
    @Published var isInitialized: Bool
    @Published var isCurrentlyCapturing: Bool = false
    @Published var isPaused: Bool = false
    @Published var measurements = [MeasurementViewModel]()
    @Published var hasError = false
    @Published var errorMessage = ""

    init(settings: Settings) {
        self.hasAcceptedCurrentPrivacyPolicy = settings.highestAcceptedPrivacyPolicy >= PrivacyPolicy.currentPrivacyPolicyVersion

        let hasValidServerURL = ApplicationState.hasValidServerURL(settings: settings)
        self.hasValidServerURL = hasValidServerURL
        self.settings = settings
        self.hasFix = false
        self.isInitialized = false
        self.tripDistance = 0.0
        self.duration = 0.0
        self.latitude = 0.0
        self.longitude = 0.0
        self.speed = 0.0

        do {
            let coreDataStack = try CoreDataManager()

            self.isLoggedIn = hasValidServerURL || (settings.authenticatedServerUrl == settings.serverUrl)
            self.dcs = DataCapturingService(sensorManager: CMMotionManager(), dataManager: coreDataStack)

            self.settings.add(serverUrlChangedListener: self)

            let bundle = Bundle(for: type(of: coreDataStack))
            try coreDataStack.setup(bundle: bundle) { [weak self] error in
                self?.isInitialized = true
            }
            self.dcs.handler.append(self.handle)

            let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
            for measurement in try persistenceLayer.loadMeasurements() {
                measurements.append(MeasurementViewModel(distance: measurement.trackLength, id: measurement.identifier))
            }
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    func acceptPrivacyPolicy() {
        settings.highestAcceptedPrivacyPolicy = PrivacyPolicy.currentPrivacyPolicyVersion
        hasAcceptedCurrentPrivacyPolicy = true
    }

    private static func hasValidServerURL(settings: Settings) -> Bool {
        if let authenticatedURL = settings.authenticatedServerUrl {
            return authenticatedURL == settings.serverUrl
        } else if let unwrappedURL = settings.serverUrl {
            if NSPredicate(format: "SELF MATCHES %@", urlRegEx).evaluate(with: unwrappedURL) {
                if URL(string: unwrappedURL) != nil {
                    return true
                } else {
                    return false
                }
            }
        }
        return false
    }

    /*private static func setupSynchronizer(for endpoint: URL, _ coreDataStack: CoreDataManager) -> (Synchronizer, CredentialsAuthenticator) {
        let sessionRegistry = SessionRegistry()
        let authenticator = CredentialsAuthenticator(authenticationEndpoint: endpoint)

        return (Synchronizer(apiURL: endpoint, coreDataStack: coreDataStack, cleaner: DeletionCleaner(), sessionRegistry: sessionRegistry, authenticator: authenticator), authenticator)
    }*/
    func startSynchronization(authenticator: CredentialsAuthenticator?) {
        guard let authenticator = authenticator else {
            hasError = true
            errorMessage = ViewError.missingAuthenticator.localizedDescription
            return
        }

        // This makes the function idempotent (ensures that multiple calls do not start synchroniation multiple times.
        if let existingAuthenticator = synchronizer?.authenticator as? CredentialsAuthenticator {
            let authenticationEndpointChanged = existingAuthenticator.authenticationEndpoint != authenticator.authenticationEndpoint
            let usernameChanged = existingAuthenticator.username != authenticator.username
            let passwordChanged = existingAuthenticator.password != authenticator.password

            let shouldStartSynchronization  = authenticationEndpointChanged || usernameChanged || passwordChanged

            guard shouldStartSynchronization else {
                return
            }

            synchronizer?.deactivate()
        }

        guard let url = settings.authenticatedServerUrl else {
            hasError = true
            errorMessage = ViewError.noAuthenticatedServerURL.localizedDescription
            return
        }

        guard let parsedURL = URL(string: url) else {
            hasError = true
            errorMessage = ViewError.authenticatedServerURLUnparseable(value: url).localizedDescription
            return
        }

        self.synchronizer = CyfaceSynchronizer(apiURL: parsedURL, coreDataStack: dcs.coreDataStack, cleaner: DeletionCleaner(), sessionRegistry: SessionRegistry(), authenticator: authenticator)
        self.synchronizer?.handler.append(self.handle)
        do {
            try self.synchronizer?.activate()
        } catch {
            hasError = true
            errorMessage = error.localizedDescription
        }
    }

    func sync() {
        synchronizer?.sync()
    }

    func deleteMeasurements(at offsets: IndexSet) throws {
        let persistenceLayer = PersistenceLayer(onManager: dcs.coreDataStack)
        for offset in offsets {
            try persistenceLayer.delete(measurement: measurements[offset].id)
            measurements.remove(at: offset)
        }
    }
}

extension ApplicationState: ServerUrlChangedListener {
    func to(validURL: URL) {
        self.isLoggedIn = false
        self.hasValidServerURL = true

        //(self.synchronizer, self.authenticator) = ApplicationState.setupSynchronizer(for: validURL, dcs.coreDataStack)
    }

    func to(invalidURL: String?) {
        self.isLoggedIn = false
        self.hasValidServerURL = false
    }
}

extension ApplicationState: UploadToggleChangedListener {
    func to(upload: Bool) {
        if upload {
            do {
                try synchronizer?.activate()
            } catch {
                hasError = true
                errorMessage = error.localizedDescription
            }
        } else {
            synchronizer?.deactivate()
        }
    }
}

extension ApplicationState: CyfaceEventHandler {
    func handle(event: DataCapturingEvent, status: Status) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            switch status {
            case .success:
                switch event {

                case .geoLocationFixAcquired:
                    self.hasFix = true
                case .geoLocationFixLost:
                    self.hasFix = false
                case .geoLocationAcquired(position: let position):
                    let persistenceLayer = PersistenceLayer(onManager: self.dcs.coreDataStack)
                    if let currentMeasurementIdentifier = self.dcs.currentMeasurement {
                        // Update the trip distance or if that fails just use the old one.
                        let currentMeasurement = try? persistenceLayer.load(measurementIdentifiedBy: currentMeasurementIdentifier)
                        self.tripDistance = currentMeasurement?.trackLength ?? self.tripDistance
                        self.latitude = position.latitude
                        self.longitude = position.longitude
                        self.speed = position.speed
                        self.duration = Date(timeIntervalSince1970: Double(currentMeasurement?.timestamp ?? 0) / 1_000.0).timeIntervalSinceNow
                    }
                case .lowDiskSpace(_): break
                case .serviceStarted(_, _):
                    self.isCurrentlyCapturing = true
                    self.isPaused = false
                case .servicePaused(_, _):
                    self.isCurrentlyCapturing = false
                    self.isPaused = true
                case .serviceResumed(_, _):
                    self.isCurrentlyCapturing = true
                    self.isPaused = false
                case .serviceStopped(measurement: let measurementIdentifier, _):
                    self.isCurrentlyCapturing = false
                    self.isPaused = false

                    guard let measurementIdentifier = measurementIdentifier else {
                        self.hasError = true
                        self.errorMessage = "Stopped service for unknown measurement."
                        return
                    }


                    do {
                        let measurement = try self.loadMeasurement(measurementIdentifier)
                        self.measurements.append(MeasurementViewModel(distance: measurement.trackLength, id: measurementIdentifier))
                    } catch {
                        self.hasError = true
                        self.errorMessage = error.localizedDescription
                    }
                case .synchronizationFinished(measurement: let measurementIdentifier):
                    self.measurements.removeAll(where: { model in
                        return model.id == measurementIdentifier
                    })
                case .synchronizationStarted(measurement: let measurementIdentifier):
                    for measurement in self.measurements {
                        print("measurement \(measurement.id)")
                    }

                    if let index = self.measurements.firstIndex(where: {model in
                        print("Found model with identifier \(model.id) == \(measurementIdentifier)")
                        return model.id == measurementIdentifier
                    }) {
                        print("Progress on index \(index)")
                        self.measurements[index].synchronizing = true
                    }
                }
            case .error(let error):
                switch event {

                case .synchronizationFinished(let measurementIdentifier):
                    self.markAsFailed(measurementIdentifier: measurementIdentifier)
                case .synchronizationStarted(let measurementIdentifier):
                    self.markAsFailed(measurementIdentifier: measurementIdentifier)
                default:
                    self.hasError = true
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func markAsFailed(measurementIdentifier: Int64) {
        if let index = self.measurements.firstIndex(where: {model in
            return model.id == measurementIdentifier
        }) {
            self.measurements[index].synchronizing = false
            self.measurements[index].synchronizationFailed = true
        }
    }

    private func loadMeasurement(_ identifier: Int64) throws -> DataCapturing.Measurement {
        let persistenceLayer = PersistenceLayer(onManager: dcs.coreDataStack)

        return try persistenceLayer.load(measurementIdentifiedBy: identifier)
    }
}
