/*
 * Copyright 2022 Cyface GmbH
 *
 * This file is part of the Cyface SDK for iOS.
 *
 * The Cyface SDK for iOS is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Cyface SDK for iOS is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Cyface SDK for iOS. If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation
import DataCapturing
import CoreMotion
import OSLog

/**
 A class encompassing all the state required everywhere in the application.

 This class also encompasses the central Cyface event handler.

 - author: Klemens Muthmann
 - version: 1.0.0
 - since: 4.0.0
 */
class ApplicationState: ObservableObject {
    // MARK: - Constants
    /// A regular expression validating a string to be a valid Uniform Resource Locator.
    static let urlRegEx = "(https?:\\/\\/[^\\/]+)(\\.[^\\/]+)?(:\\d+)?(\\/.+)*\\/?"

    // MARK: - Properties
    /// The system settings for the Cyface application
    let settings: Settings
    /// The Cyface `DataCapturingService`, which forms a facade to all the data capturing functionality of the Cyface SDK.
    var dcs: DataCapturingService
    /// The synchronizer to transmit data to a Cyface data collection server.
    var synchronizer: Synchronizer?
    /// This is `true` if the most recent privacy policy has been accepted by the user or `false` otherwise. Depending on the value of this flag, the application either shows the privacy policy screen or not.
    @Published var hasAcceptedCurrentPrivacyPolicy: Bool
    /// This is `true` if the user has been logged in or `false` otherwise. Depending on the state of this flag the app either shows a login screen or the main screen.
    var isLoggedIn: Bool
    /// Is there currently a valid Cyface server set in the application settings. If not this can be used to force the user to enter one such URL.
    @Published var hasValidServerURL: Bool
    /// Is the application properly initialized? This information is used to show a splash screen on startup, which disappears after initialization has finished. Initialization at the moment is the setup of the CoreDataStack, which can include data migration from previous database versions.
    @Published var isInitialized: Bool
    /// This is `true` if data capturing is active and `false` otherwise. Depending on this value, buttons are without function and the UI for the current measurement is shown.
    @Published var isCurrentlyCapturing: Bool = false
    /// Used to decide on whether to show the pause UI elements or not. This usually means that the capturing bar is displayed, but the pause button is disabled while the play and the stop button are enabled.
    @Published var isPaused: Bool = false
    /// The list of measurements currently shown via the user interface.
    @Published var measurements = [MeasurementViewModel]()
    /// `true` if the UI is supposed to display an error message; `false` otherwise.
    @Published var hasError = false
    /// The error message to show if `hasError` is `true`.
    @Published var errorMessage = ""

    // MARK: - Initializers
    /// Create a new `ApplicationState` from the system settings of this application.
    init(settings: Settings) {
        self.hasAcceptedCurrentPrivacyPolicy = settings.highestAcceptedPrivacyPolicy >= PrivacyPolicy.currentPrivacyPolicyVersion

        let hasValidServerURL = ApplicationState.hasValidServerURL(settings: settings)
        self.hasValidServerURL = hasValidServerURL
        self.settings = settings
        self.isInitialized = false

        do {
            self.isLoggedIn = hasValidServerURL || (settings.authenticatedServerUrl == settings.serverUrl)
            
            let coreDataStack = try CoreDataManager()
            let bundle = Bundle(for: type(of: coreDataStack))

            self.dcs = DataCapturingService(sensorManager: CMMotionManager(), dataManager: coreDataStack)
            try coreDataStack.setup(bundle: bundle) { [weak self] error in
                self?.isInitialized = true
            }
            self.dcs.handler.append(self.handle)
            self.dcs.setup()

            self.settings.add(serverUrlChangedListener: self)
            self.settings.add(uploadToggleChangedListener: self)

            let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
            for measurement in try persistenceLayer.loadSynchronizableMeasurements() {
                measurements.append(MeasurementViewModel(distance: measurement.trackLength, id: measurement.identifier))
            }
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    // MARK: - Methods
    /// Called if the user accepts the privacy policy.
    func acceptPrivacyPolicy() {
        settings.highestAcceptedPrivacyPolicy = PrivacyPolicy.currentPrivacyPolicyVersion
        hasAcceptedCurrentPrivacyPolicy = true
    }

    /**
     This function makes it possible to create the ``Synchronizer`` based on the ``Authenticator`` created during login.

     The function should be called after a successful login to setup the `Synchronizer` correctly and activate data synchronization. Calling this multiple times is ok. The function is idempotent.

     - param authenticator: If `nil` the error status of the application is set to `true` and the error message from ``ViewError.missingAuthenticator`` will be set into the ``errorMessage`` attribute.
     */
    func startSynchronization(authenticator: CredentialsAuthenticator?) {
        os_log("Starting Synchronization")

        guard let authenticator = authenticator else {
            hasError = true
            errorMessage = ViewError.missingAuthenticator.localizedDescription
            return
        }

        // This makes the function idempotent (ensures that multiple calls do not start synchronization multiple times.
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
            if settings.synchronizeData {
                try self.synchronizer?.activate()
            } else {
                os_log("Not Starting Synchronization, since it is switched off in the settings.")
                return
            }
        } catch {
            hasError = true
            errorMessage = error.localizedDescription
        }
    }

    /// Force the application to synchronize measurements with the server.
    func sync() {
        synchronizer?.sync()
    }

    // Called if the user deletes one or more measurements.
    func deleteMeasurements(at offsets: IndexSet) throws {
        let persistenceLayer = PersistenceLayer(onManager: dcs.coreDataStack)
        for offset in offsets {
            try persistenceLayer.delete(measurement: measurements[offset].id)
            measurements.remove(at: offset)
        }
    }

    // MARK: - Private Methods
    /// Checks if the settings contain a valid Cyface server URL at the moment.
    /// 
    /// - Parameter settings: The App settings containing the server URL
    /// - Returns: `true` if a valid server URL has been provided by the user via the applications system settings.
    private static func hasValidServerURL(settings: Settings) -> Bool {
        if let unwrappedURL = settings.serverUrl {
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

extension ApplicationState: ServerUrlChangedListener {
    func to(validURL: URL) {
        self.isLoggedIn = false
        self.hasValidServerURL = true

        synchronizer?.deactivate()
    }

    func to(invalidURL: String?) {
        self.isLoggedIn = false
        self.hasValidServerURL = false

        synchronizer?.deactivate()
    }
}

extension ApplicationState: UploadToggleChangedListener {
    func to(upload: Bool) {
        if upload && isLoggedIn {
            os_log("User activated synchronization!")
            do {
                try synchronizer?.activate()
            } catch {
                hasError = true
                errorMessage = error.localizedDescription
            }
        } else {
            os_log("User deactivated synchronization!")
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

                case .geoLocationFixAcquired: break
                case .geoLocationFixLost: break
                case .geoLocationAcquired(position: _): break
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

                    if self.settings.synchronizeData {
                        self.synchronizer?.syncChecked()
                    }
                case .synchronizationFinished(measurement: let measurementIdentifier):
                    self.measurements.removeAll(where: { model in
                        return model.id == measurementIdentifier
                    })
                case .synchronizationStarted(measurement: let measurementIdentifier):
                    if let index = self.measurements.firstIndex(where: {model in
                        return model.id == measurementIdentifier
                    }) {
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

    /// Mark the measurement as a failed upload.
    private func markAsFailed(measurementIdentifier: Int64) {
        if let index = self.measurements.firstIndex(where: {model in
            return model.id == measurementIdentifier
        }) {
            self.measurements[index].synchronizing = false
            self.measurements[index].synchronizationFailed = true
        }
    }

    /// Load the measurement from persistent storage.
    private func loadMeasurement(_ identifier: Int64) throws -> DataCapturing.Measurement {
        let persistenceLayer = PersistenceLayer(onManager: dcs.coreDataStack)

        return try persistenceLayer.load(measurementIdentifiedBy: identifier)
    }
}
