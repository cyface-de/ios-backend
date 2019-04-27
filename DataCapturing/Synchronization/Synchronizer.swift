/*
 * Copyright 2019 Cyface GmbH
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

/**
 An instance of this class synchronizes captured measurements from persistent storage to a Cyface server.

 An object of this call can be used to synchronize data either in the foreground or in the background.
 Background synchronization happens only if the synchronizing device has an active Wifi connection.
 To activate background synchronization you need to call the `activate` method.
 Background synchronization is called as soon as WiFi becomes available or every 60 minutes.

 - Author: Klemens Muthmann
 - Version: 2.1.0
 - Since: 2.3.0
 */
public class Synchronizer {

    // MARK: - Properties
    private let log = OSLog.init(subsystem: "Synchronizer", category: "de.cyface")

    /// Stack used to access *CoreData*.
    private let coreDataStack: CoreDataManager

    /// A strategy for cleaning the persistent storage after data synchronization.
    private let cleaner: Cleaner

    /// A connection to a Cyface server used to synchronize the data to.
    private let serverConnection: ServerConnection

    /// Handles background synchronization of available `Measurement`s.
    let reachabilityManager: NetworkReachabilityManager

    /// A queue to run synchronization on. This prevents the same measurement to be transmitted multiple times.
    private let serverSynchronizationQueue = DispatchQueue(label: "de.cyface.synchronization", qos: DispatchQoS.background)

    /// Whether there is a data synchronization in progress or not.
    private var synchronizationInProgress = false

    /// The measurements to synchonize in the current synchronization run.
    private var countOfMeasurementsToSynchronize = 0

    /// The handler to call, when synchronization for a measurement has finished.
    private let handler: (DataCapturingEvent, Status) -> Void

    /// A timer called regularly to check for available measurements and synchronize them if not done yet.
    private let dataSynchronizationTimer: RepeatingTimer

    /// A queue synchronizing access to the Alamofire `NetworkReachabilityManager`.
    private let isReachableCheckingQueue = DispatchQueue.global(qos: .background)

    /**
     A flag indicating whether synchronization of data should only happen if the device is connected to a wireless local area network (Wifi).

     If `true` data is only synchronized via Wifi; if `false` data is also synchronized via mobile network.
     The default setting is `true`.
     Setting this to `false` might put heavy load on the users device and deplete her or his data plan.
     */
    public var syncOnWiFiOnly = true

    // MARK: - Initializers

    /**
     Initializer that sets the initial value of all the properties and prepares the background synchronization job.

     - Parameters:
        - coreDataStack: Stack used to access *CoreData*.
        - cleaner: A strategy for cleaning the persistent storage after data synchronization.
        - serverConnection: An authenticated connection to a Cyface API server.
        - handler: The handler to call, when synchronization for a measurement has finished.
     - Throws: `SynchronizationError.reachabilityNotInitilized`: If the synchronizer was unable to initialize the reachability service that surveys the Wifi connection and starts synchronization if Wifi is available.
     */
    public init(coreDataStack: CoreDataManager, cleaner: Cleaner, serverConnection: ServerConnection, handler: @escaping (DataCapturingEvent, Status) -> Void) throws {
        self.coreDataStack = coreDataStack
        self.cleaner = cleaner
        self.serverConnection = serverConnection
        self.handler = handler
        // Try to synchronize once per hour.
        dataSynchronizationTimer = RepeatingTimer(timeInterval: 60 * 60)
        guard let reachabilityManager = NetworkReachabilityManager(host: serverConnection.apiURL.absoluteString) else {
            throw SynchronizationError.reachabilityNotInitialized
        }
        self.reachabilityManager = reachabilityManager
        self.reachabilityManager.listener = { [weak self] _ in
            guard let self = self else {
                return
            }

            if self.isReachable() {
                self.sync()
            }
        }

        dataSynchronizationTimer.eventHandler = { [weak self] in
            guard let self = self else {
                return
            }

            let status = self.isReachable()
            print(status)
            if status {
                self.sync()
            }
        }
    }

    /**
     Makes sure background synchronization is stopped when this object dies.
     */
    deinit {
        self.reachabilityManager.stopListening()
        dataSynchronizationTimer.suspend()
    }

    // MARK: - API Methods

    /**
     Synchronize all measurements now if a connection is available.

     If this is not called the service might wait for an opportune moment to start synchronization.
     The call is asynchronous, meaning it returns almost immediately, while the synchronization continues running inside its own thread.

     You may call this method multiple times in short succession.
     However only one synchronization can be active at a given time.
     If you call this during an active synchronization it is going to return without doing anything.
     */
    public func sync() {
        serverSynchronizationQueue.async { [weak self] in
            guard let self = self else {
                return
            }

            if self.synchronizationInProgress {
                return
            } else {
                self.synchronizationInProgress = true
            }

            do {
                let persistenceLayer = PersistenceLayer(onManager: self.coreDataStack)
                persistenceLayer.context = persistenceLayer.makeContext()
                let measurements = try persistenceLayer.loadSynchronizableMeasurements()
                self.handle(synchronizableMeasurements: measurements, status: .success)
            } catch let error {
                self.handle(synchronizableMeasurements: nil, status: .error(error))
            }
        }
    }

    /**
     Starts background synchronization as prepared in this objects initializer.
     */
    public func activate() {
        if isReachable() {
            sync()
        }
        reachabilityManager.startListening()
        dataSynchronizationTimer.resume()
    }

    /**
     Stops background synchronization.
     */
    public func deactivate() {
        reachabilityManager.stopListening()
        dataSynchronizationTimer.suspend()
    }

    // MARK: - Internal Methods

    /**
     Synchronizes the array of provided measurements if the status was successful and measurements are provided

     - Parameters:
        - synchronizableMeasurements: The synchronizable measurements to synchronize or `nil` if they have not been loaded.
        - status: Provides the status of whether loading the measurements was successful or not.
     */
    private func handle(synchronizableMeasurements: [MeasurementMO]?, status: Status) {
        guard let measurements = synchronizableMeasurements else {
            return
        }

        countOfMeasurementsToSynchronize = measurements.count
        // If this is 0 initially, there have been no measurements for synchronization in the data storage. So we just stop processing
        guard countOfMeasurementsToSynchronize > 0 else {
            reachabilityManager.stopListening()
            synchronizationInProgress = false
            return
        }

        for measurement in measurements {
            guard let measurementContextString = measurement.context else {
                fatalError("Synchronizer.handle(synchronizableMeasurements: \(String(describing: synchronizableMeasurements?.count)), \(status)): Unable to load measurement context from measurement \(measurement.identifier).")
            }
            guard let measurementContext = MeasurementContext(rawValue: measurementContextString) else {
                fatalError("Synchronizer.handle(synchronizableMeasurements: \(String(describing: synchronizableMeasurements?.count)), \(status)): Invalid measurement context: \(measurementContextString) in database.")
            }

            let measurementEntity = MeasurementEntity(identifier: measurement.identifier, context: measurementContext)

            handler(.synchronizationStarted(measurement: measurementEntity), .success)
            serverConnection.sync(measurement: MeasurementEntity(identifier: measurement.identifier, context: measurementContext), onSuccess: successHandler, onFailure: failureHandler)
        }
    }

    /**
     Handles the successful synchronization of a single measurement.

     - Parameter measurement: The synchronized measurement.
     */
    private func successHandler(measurement: MeasurementEntity) {
        do {
            let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
            try cleaner.clean(measurement: measurement, from: persistenceLayer)
            handler(.synchronizationFinished(measurement: measurement), .success)
        } catch let error {
            handler(.synchronizationFinished(measurement: measurement), .error(error))
        }

        synchronizationFinishedHandler()
    }

    /**
     Handles the failed synchronization of a single measurement.

     - Parameters:
        - measurement: The measurement for which the synchronization failed.
        - error: The error causing the failure.
     */
    private func failureHandler(measurement: MeasurementEntity, error: Error) {
        os_log("Unable to upload data for measurement: %@!", log: log, type: .error, NSNumber(value: measurement.identifier))
        os_log("Error: %@", log: log, type: .error, error.localizedDescription)
        handler(.synchronizationFinished(measurement: measurement), .error(error))
        synchronizationFinishedHandler()
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

    private func isReachable() -> Bool {
        var ret = false
        isReachableCheckingQueue.sync {

            if self.syncOnWiFiOnly {
                ret = NetworkReachabilityManager()?.isReachableOnEthernetOrWiFi ?? false
            } else {
                ret = NetworkReachabilityManager()?.isReachable ?? false
            }
        }

        return ret
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
    func clean(measurement: MeasurementEntity, from persistenceLayer: PersistenceLayer) throws
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

    public func clean(measurement: MeasurementEntity, from persistenceLayer: PersistenceLayer) throws {
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

    public func clean(measurement: MeasurementEntity, from persistenceLayer: PersistenceLayer) throws {
        try persistenceLayer.clean(measurement: measurement)
    }
}

/**
 Enumeration of all the errors that might happen during data synchronization (except for `ServerConnectionError` cases).

 ```
 case reachabilityNotInitialized
 ```

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 2.3.0
 */
public enum SynchronizationError: Error {
    /// If the background reachability checker was not successfully initialized.
    case reachabilityNotInitialized
}
