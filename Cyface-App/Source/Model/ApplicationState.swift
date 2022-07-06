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
        switch event {

        case .geoLocationFixAcquired:
            self.hasFix = true
        case .geoLocationFixLost:
            self.hasFix = false
        case .geoLocationAcquired(position: let position):
            let persistenceLayer = PersistenceLayer(onManager: dcs.coreDataStack)
            if let currentMeasurementIdentifier = dcs.currentMeasurement {
                // Update the trip distance or if that fails just use the old one.
                let currentMeasurement = try? persistenceLayer.load(measurementIdentifiedBy: currentMeasurementIdentifier)
                tripDistance = currentMeasurement?.trackLength ?? tripDistance
                latitude = position.latitude
                longitude = position.longitude
                speed = position.speed
                duration = Date(timeIntervalSince1970: Double(currentMeasurement?.timestamp ?? 0) / 1_000.0).timeIntervalSinceNow
            }
        case .lowDiskSpace(allocation: let allocation): break
        case .serviceStarted(_, _):
            isCurrentlyCapturing = true
            isPaused = false
        case .servicePaused(_, _):
            isCurrentlyCapturing = false
            isPaused = true
        case .serviceResumed(_, _):
            isCurrentlyCapturing = true
            isPaused = false
        case .serviceStopped(measurement: let measurementIdentifier, event: let event):
            isCurrentlyCapturing = false
            isPaused = false

            guard let measurementIdentifier = measurementIdentifier else {
                hasError = true
                errorMessage = "Stopped service for unknown measurement."
                return
            }


            do {
                let measurement = try loadMeasurement(measurementIdentifier)
                measurements.append(MeasurementViewModel(distance: measurement.trackLength, id: measurementIdentifier))
            } catch {
                hasError = true
                errorMessage = error.localizedDescription
            }
        case .synchronizationFinished(measurement: let measurementIdentifier):
            do {
                let measurement = try loadMeasurement(measurementIdentifier)
                if measurement.synchronized {
                    measurements.removeAll(where: { model in
                        return model.id == measurementIdentifier
                    })
                } else {
                    // Synchronization failed. Show error indicator.
                    if let index = measurements.firstIndex(where: {model in
                        return model.id == measurementIdentifier
                    }) {
                        measurements[index].synchronizing = false
                        measurements[index].synchronizationFailed = true
                    }
                }
            } catch {
                hasError = true
                errorMessage = error.localizedDescription
            }
        case .synchronizationStarted(measurement: let measurementIdentifier):
            do {
                let measurement = try loadMeasurement(measurementIdentifier)
                if let index = measurements.firstIndex(where: {model in
                    model.id == measurementIdentifier
                }) {
                    measurements[index].synchronizing = true
                }
            } catch {
                hasError = true
                errorMessage = error.localizedDescription
            }
        }
    }

    private func loadMeasurement(_ identifier: Int64) throws -> DataCapturing.Measurement {
        let persistenceLayer = PersistenceLayer(onManager: dcs.coreDataStack)

        return try persistenceLayer.load(measurementIdentifiedBy: identifier)
    }
}
