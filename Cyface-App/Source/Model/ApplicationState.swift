//
//  ApplicationState.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 19.06.22.
//

import Foundation
import DataCapturing
import CoreMotion

class ApplicationState: ObservableObject, ServerUrlChangedListener {
    static let urlRegEx = "(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+"

    let settings: Settings
    let dcs: DataCapturingService
    @Published var hasAcceptedCurrentPrivacyPolicy: Bool
    @Published var isLoggedIn: Bool
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
        self.isLoggedIn = hasValidServerURL || (settings.authenticatedServerUrl == settings.serverUrl)
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

            self.dcs = DataCapturingService(sensorManager: CMMotionManager(), dataManager: coreDataStack)

            self.settings.add(serverUrlChangedListener: self)

            let bundle = Bundle(for: type(of: coreDataStack))
            try coreDataStack.setup(bundle: bundle) { [weak self] error in
                self?.isInitialized = true
            }
            self.dcs.handler.append(self.handle)
        } catch {
            fatalError("Unable to initialize CoreData Stack!")
        }
    }

    func acceptPrivacyPolicy() {
        settings.highestAcceptedPrivacyPolicy = PrivacyPolicy.currentPrivacyPolicyVersion
        hasAcceptedCurrentPrivacyPolicy = true
    }

    func toValidUrl() {
        self.isLoggedIn = false
        self.hasValidServerURL = true
    }

    func toInvalidUrl() {
        self.isLoggedIn = false
        self.hasValidServerURL = false
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


}

extension ApplicationState: CyfaceEventHandler {
    func handle(event: DataCapturingEvent, status: Status) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

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
                do {
                    let measurement = try self.loadMeasurement(measurementIdentifier)
                    if measurement.synchronized {
                        self.measurements.removeAll(where: { model in
                            return model.id == measurementIdentifier
                        })
                    } else {
                        // Synchronization failed. Show error indicator.
                        if let index = self.measurements.firstIndex(where: {model in
                            return model.id == measurementIdentifier
                        }) {
                            self.measurements[index].synchronizing = false
                            self.measurements[index].synchronizationFailed = true
                        }
                    }
                } catch {
                    self.hasError = true
                    self.errorMessage = error.localizedDescription
                }
            case .synchronizationStarted(measurement: let measurementIdentifier):
                if let index = self.measurements.firstIndex(where: {model in
                    model.id == measurementIdentifier
                }) {
                    self.measurements[index].synchronizing = true
                }
            }
        }
    }

    private func loadMeasurement(_ identifier: Int64) throws -> DataCapturing.Measurement {
        let persistenceLayer = PersistenceLayer(onManager: dcs.coreDataStack)

        return try persistenceLayer.load(measurementIdentifiedBy: identifier)
    }
}
