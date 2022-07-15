/*
 * Copyright 2019 - 2022 Cyface GmbH
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
import os.log
import Alamofire

// MARK: - Synchronizer Protocol

/**
 An instance of this class synchronizes captured measurements from persistent storage to a Cyface server.

 An object of this call can be used to synchronize data either in the foreground or in the background.
 Background synchronization happens only if the synchronizing device has an active Wifi connection.
 To activate background synchronization you need to call the `activate` method.
 Background synchronization is called as soon as WiFi becomes available or every 60 minutes.
 For foreground synchronization use `syncChecked()`.

 - Author: Klemens Muthmann
 - Version: 4.0.2
 - Since: 2.3.0
 */
public protocol Synchronizer {

    // MARK: - Properties

    /// The list of handler to call, when synchronization for a measurement has finished.
    var handler: [(DataCapturingEvent, Status) -> Void] { get set }

    /**
     A flag indicating whether synchronization of data should only happen if the device is connected to a wireless local area network (Wifi).

     If `true` data is only synchronized via Wifi; if `false` data is also synchronized via mobile network.
     The default setting is `true`.
     Setting this to `false` might put heavy load on the users device and deplete her or his data plan.
     */
    var syncOnWiFiOnly: Bool { get set }

    /// The authenticator to check if the current user has a valid user account.
    var authenticator: Authenticator { get }

    // MARK: - API Methods

    /**
     Tries to synchronize all measurements after checking for a proper connection. If `syncOnWiFiOnly` is true, this will only work if the device is connected to a WiFi network.
    */
    func syncChecked()

    /**
     Synchronize all measurements now.

     The call is asynchronous, meaning it returns almost immediately, while the synchronization continues running inside its own thread.

     You may call this method multiple times in short succession.
     However only one synchronization can be active at a given time.
     If you call this during an active synchronization it is going to return without doing anything.
     */
    func sync()

    /**
     Starts background synchronization as prepared in this objects initializer.

     - throws: `SynchronizerError.missingHost` If tha `apiURL` provides no valid hostname.
     - throws: `SynchronizerError.unableToBuildReachabilityManager` if the Alamofire `NetworkReachabilityManager` could not be created for the current host.
     - throws: `SynchronizationError.reachabilityStartFailed` if the system was unable to start listening for reachability changes.
     */
    func activate() throws

    /**
     Stops background synchronization.
     */
    func deactivate()
}

public class CyfaceSynchronizer: Synchronizer {

    // MARK: - Properties

    public var handler = [(DataCapturingEvent, Status) -> Void]()

    public var syncOnWiFiOnly = true

    public let authenticator: Authenticator

    /// The logger used for objects of this class.
    private static let log = OSLog.init(subsystem: "Synchronizer", category: "de.cyface")

    /// The URL to a Cyface server
    private let apiURL: URL

    /// Stack used to access *CoreData*.
    private let coreDataStack: CoreDataManager

    /// A strategy for cleaning the persistent storage after data synchronization.
    private let cleaner: Cleaner

    /// A registry for open server sessions, used to repeat those sessions if possible.
    private let sessionRegistry: SessionRegistry

    /// Handles background synchronization of available `Measurement`s.
    var reachabilityManager: NetworkReachabilityManager?

    /// A queue to run synchronization on. This prevents the same measurement to be transmitted multiple times.
    private let serverSynchronizationQueue = DispatchQueue(label: "de.cyface.synchronization", qos: DispatchQoS.background)

    /// Whether there is a data synchronization in progress or not.
    private var synchronizationInProgress = false

    /// The measurements to synchonize in the current synchronization run.
    private var countOfMeasurementsToSynchronize = 0

    /// A timer called regularly to check for available measurements and synchronize them if not done yet.
    private let dataSynchronizationTimer: RepeatingTimer

    /// A queue synchronizing access to the Alamofire `NetworkReachabilityManager`.
    private let isReachableCheckingQueue = DispatchQueue.global(qos: .background)

    /// Flag on whether the Cyface server is reachable on ethernet or WiFi.
    private var isReachableOnEthernetOrWifi = false

    /// Flag on whether the Cyface server is reachable at all (including mobile).
    private var isReachable = false

    // MARK: - Initializers

    /**
     Initializer that sets the initial value of all the properties and prepares the background synchronization job.

     - Parameters:
        - apiURL: The URL to a Cyface API
        - coreDataStack: Stack used to access *CoreData*.
        - cleaner: A strategy for cleaning the persistent storage after data synchronization.
        - sessionRegistry: A registry to store open server sessions, to try to repeat instead of restart an upload.
        - authenticator: The authenticator to use to check on the server on whether the current user is valid or not.
        - handler: The handler to call, when synchronization for a measurement has finished.
     */
    public init(apiURL: URL, coreDataStack: CoreDataManager, cleaner: Cleaner, sessionRegistry: SessionRegistry = SessionRegistry(), authenticator: Authenticator) {
        self.coreDataStack = coreDataStack
        self.apiURL = apiURL
        self.cleaner = cleaner
        self.sessionRegistry = sessionRegistry
        self.authenticator = authenticator
        // Try to synchronize once per hour.
        dataSynchronizationTimer = RepeatingTimer(timeInterval: 60 * 60)

        dataSynchronizationTimer.eventHandler = { [weak self] in
            guard let self = self else {
                return
            }

            self.syncChecked()
        }
    }

    /**
     Makes sure background synchronization is stopped when this object dies.
     */
    deinit {
        self.reachabilityManager?.stopListening()
        dataSynchronizationTimer.suspend()
    }

    // MARK: - API Methods

    public func syncChecked() {
        self.isReachableCheckingQueue.sync {
            if syncOnWiFiOnly && isReachableOnEthernetOrWifi {
                sync()
            } else if !syncOnWiFiOnly && isReachable {
                sync()
            }
        }
    }

    public func sync() {
        serverSynchronizationQueue.async { [weak self] in
            guard let self = self else {
                return
            }

            // TODO: This can lead to a crash as it is possible that two executions step over this.
            if self.synchronizationInProgress {
                return
            } else {
                self.synchronizationInProgress = true
            }

            do {
                let persistenceLayer = PersistenceLayer(onManager: self.coreDataStack)
                let measurements = try persistenceLayer.loadSynchronizableMeasurements()
                self.handle(synchronizableMeasurements: measurements, status: .success)
            } catch let error {
                self.handle(synchronizableMeasurements: nil, status: .error(error))
            }
        }
    }

    public func activate() throws {
        os_log("Activating Synchronization", log: CyfaceSynchronizer.log, type: .debug)

        guard let host = apiURL.host else {
            throw SynchronizerError.missingHost
        }
        guard let reachabilityManager = NetworkReachabilityManager(host: host) else {
            throw SynchronizerError.unableToBuildReachabilityManager
        }
        // Initial sync
        syncChecked()
        let reachabilityManagerStarted = reachabilityManager.startListening { status in
            switch status {
            case .reachable(.ethernetOrWiFi):
                self.isReachableOnEthernetOrWifi = true
                self.isReachable = true
            case .notReachable:
                self.isReachableOnEthernetOrWifi = false
                self.isReachable = false
            default:
                self.isReachableOnEthernetOrWifi = false
                self.isReachable = true
            }

            self.syncChecked()
        }
        guard reachabilityManagerStarted else {
            throw SynchronizerError.reachabilityStartFailed
        }
        //
        self.reachabilityManager = reachabilityManager

        dataSynchronizationTimer.resume()
    }

    public func deactivate() {
        reachabilityManager?.stopListening()
        dataSynchronizationTimer.suspend()
    }

    // MARK: - Internal Methods

    /**
     Synchronizes the array of provided measurements if the status was successful and measurements are provided

     - Parameters:
        - synchronizableMeasurements: The synchronizable measurements to synchronize or `nil` if they have not been loaded.
        - status: Provides the status of whether loading the measurements was successful or not.
     */
    private func handle(synchronizableMeasurements: [Measurement]?, status: Status) {
        guard let measurements = synchronizableMeasurements else {
            return
        }

        countOfMeasurementsToSynchronize = measurements.count
        // If this is 0 initially, there have been no measurements for synchronization in the data storage. So we just stop processing
        guard countOfMeasurementsToSynchronize > 0 else {
            synchronizationInProgress = false
            return
        }
        let uploadProcess = UploadProcess(
            apiUrl: apiURL,
            sessionRegistry: sessionRegistry,
            authenticator: authenticator,
            onSuccess: successHandler,
            onFailure: failureHandler)

        for measurement in measurements {
            handle(.synchronizationStarted(measurement: measurement.identifier), .success)
            let upload = CoreDataBackedUpload(coreDataStack: coreDataStack, identifier: UInt64(measurement.identifier))
            uploadProcess.upload(upload)
        }
    }

    /**
     Handles the successful synchronization of a single measurement.

     - Parameter measurement: The synchronized measurement.
     */
    private func successHandler(measurement: UInt64) {
        do {
            let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
            try cleaner.clean(measurement: Int64(measurement), from: persistenceLayer)
            handle(.synchronizationFinished(measurement: Int64(measurement)), .success)
        } catch let error {
            handle(.synchronizationFinished(measurement: Int64(measurement)), .error(error))
        }

        synchronizationFinishedHandler()
    }

    /**
     Handles the failed synchronization of a single measurement.

     - Parameters:
        - measurement: The measurement for which the synchronization failed.
        - error: The error causing the failure.
     */
    private func failureHandler(measurement: UInt64, error: Error) {
        os_log("Unable to upload data for measurement: %d!", log: CyfaceSynchronizer.log, type: .error, measurement)
        os_log("Error: %{public}@", log: CyfaceSynchronizer.log, type: .error, error.localizedDescription)
        handle(.synchronizationFinished(measurement: Int64(measurement)), .error(error))
        synchronizationFinishedHandler()
    }

    private func handle(_ event: DataCapturingEvent, _ status: Status) {
        for h in handler {
            h(event, status)
        }
    }

    /**
     Called when all measurements of the current synchronization where tried once.
     */
    private func synchronizationFinishedHandler() {
        serverSynchronizationQueue.async { [weak self] in
            guard let self = self else {
                return
            }

            self.countOfMeasurementsToSynchronize -= 1
            if self.countOfMeasurementsToSynchronize==0 {
                self.synchronizationInProgress = false
            }
        }
    }

    /**
     Errors thrown during data synchronization.

     - author: Klemens Muthmann
     - version: 1.0.0
     */
    public enum SynchronizerError: Error {
        /// If the host of the server to synchronize to is missing.
        case missingHost
        /// If the Alamofire reachability manager could not be built.
        case unableToBuildReachabilityManager
        /// If starting reachability checks fails.
        case reachabilityStartFailed
    }
}

/**
 Implementations of this protocol are responsible for cleaning the database after a synchronization run.

 - Author: Klemens Muthmann
 - Version: 2.0.0
 - Since: 2.3.0
 */
public protocol Cleaner {

    /**
     Cleans the database after a measurement has been synchronized.

     - Parameters:
        - measurement: The measurement to clean.
        - from: The `PersistenceLayer` to call for cleaning the data.
     - Throws:
        - `PersistenceError.measurementNotLoadable` If the measurement to delete was not available.
        - `PersistenceError.noContext` If there is no current context and no background context can be created. If this happens something is seriously wrong with CoreData.
        - Some unspecified errors from within CoreData.
        - Some internal file system error on failure of creating or accessing the accelerations file at the required path.
     */
    func clean(measurement: Int64, from persistenceLayer: PersistenceLayer) throws
}

/**
 A cleaner removing each synchronized measurement from the database completely.

 - Author: Klemens Muthmann
 - Version: 2.0.0
 - Since: 2.3.0
 */
public class DeletionCleaner: Cleaner {

    /// Public default constructor required to create instances of this class.
    public init() {
        // Nothing to do here
    }

    public func clean(measurement: Int64, from persistenceLayer: PersistenceLayer) throws {
        try persistenceLayer.delete(measurement: measurement)
    }
}

/**
 A cleaner removing only the accelerations from each synchronized measurement, thus keeping the track information available.

 - Author: Klemens Muthmann
 - Version: 2.0.0
 - Since: 2.3.0
 */
public class AccelerationPointRemovalCleaner: Cleaner {

    /// Public default constructor required to create instances of this class.
    public init() {
        // Nothing to do here
    }

    public func clean(measurement: Int64, from persistenceLayer: PersistenceLayer) throws {
        try persistenceLayer.clean(measurement: measurement)
    }
}
