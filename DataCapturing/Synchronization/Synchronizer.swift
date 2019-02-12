//
//  Synchronizer.swift
//  DataCapturing
//
//  Created by Team Cyface on 12.02.19.
//  Copyright © 2019 Cyface GmbH. All rights reserved.
//

import Foundation
import os.log
import Alamofire

public class Synchronizer {

    // MARK: - Properties

    private let persistenceLayer: PersistenceLayer
    private let cleaner: Cleaner
    private let serverConnection: ServerConnection
    /// Handles background synchronization of available `Measurement`s.
    let reachabilityManager: NetworkReachabilityManager

    /// A queue to run synchronization on. This prevents the same measurement to be transmitted multiple times.
    private let serverSynchronizationQueue = DispatchQueue(label: "de.cyface.synchronization", qos: DispatchQoS.background)

    /// Whether there is a data synchronization in progress or not.
    private var synchronizationInProgress = false

    private var countOfMeasurementsToSynchronize = 0

    private let handler: (DataCapturingEvent) -> Void

    /**
     A flag indicating whether synchronization of data should only happen if the device is connected to a wireless local area network (Wifi).

     If `true` data is only synchronized via Wifi; if `false` data is also synchronized via mobile network.
     The default setting is `true`.
     Setting this to `false` might put heavy load on the users device and deplete her or his data plan.
     */
    public var syncOnWiFiOnly = true

    // MARK: - Initializers

    /**
     - Parameters:
     - persistenceLayer:
     - cleaner: 
     - serverConnection: An authenticated connection to a Cyface API server.
     */
    init(persistenceLayer: PersistenceLayer, cleaner: Cleaner, serverConnection: ServerConnection, handler: @escaping (DataCapturingEvent) -> Void) throws {
        self.persistenceLayer = persistenceLayer
        self.cleaner = cleaner
        self.serverConnection = serverConnection
        self.handler = handler
        guard let reachabilityManager = NetworkReachabilityManager(host: serverConnection.apiURL.absoluteString) else {
            throw SynchronizationError.reachabilityNotInitialized
        }
        self.reachabilityManager = reachabilityManager
        self.reachabilityManager.listener = { [weak self] status in
            guard let self = self else {
                return
            }

            let reachable = self.syncOnWiFiOnly ?  status == NetworkReachabilityManager.NetworkReachabilityStatus.reachable(.ethernetOrWiFi) : status == NetworkReachabilityManager.NetworkReachabilityStatus.reachable(.wwan) || status == NetworkReachabilityManager.NetworkReachabilityStatus.reachable(.ethernetOrWiFi)

            if reachable {
                self.sync()
            }
        }
    }

    deinit {
        self.reachabilityManager.stopListening() 
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

            self.persistenceLayer.loadSynchronizableMeasurements(onFinishedCall: self.handle)
        }
    }

    public func activate() {
        reachabilityManager.startListening()
    }

    // MARK: - Internal Methods

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
                fatalError("Unable to load measurement context from measurement \(measurement.identifier).")
            }
            guard let measurementContext = MeasurementContext(rawValue: measurementContextString) else {
                fatalError("Invalid measurement context: \(measurementContextString) in database.")
            }

            let measurementEntity = MeasurementEntity(identifier: measurement.identifier, context: measurementContext)

            handler(.synchronizationStarted(measurement: measurementEntity))
            serverConnection.sync(measurement: MeasurementEntity(identifier: measurement.identifier, context: measurementContext), onSuccess: successHandler, onFailure: failureHandler)
        }
    }

    private func successHandler(measurement: MeasurementEntity) {
        cleaner.clean(measurement: measurement, from: persistenceLayer) { [weak self] status in
            guard let self = self else {
                return
            }

            self.handler(.synchronizationFinished(measurement: measurement, status: status))
        }
        synchronizationFinishedHandler()
    }

    private func failureHandler(measurement: MeasurementEntity, error: Error) {
        os_log("Unable to upload data for measurement: %@!", NSNumber(value: measurement.identifier))
        os_log("Error: %@", error.localizedDescription)
        handler(.synchronizationFinished(measurement: measurement, status: .error(error)))
        synchronizationFinishedHandler()
    }

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
}

public protocol Cleaner {

    /**
     Cleans the database after a measurement has been synchronized.

     - Parameters:
     - measurement: The measurement to clean.
     - handler: Called as soon as deletion has finished.
     */
    func clean(measurement: MeasurementEntity, from persistenceLayer: PersistenceLayer, onFinishedCall handler:@escaping (Status) -> Void)
}

public class DeletionCleaner: Cleaner {
    public func clean(measurement: MeasurementEntity, from persistenceLayer: PersistenceLayer, onFinishedCall handler:@escaping (Status) -> Void) {
        persistenceLayer.delete(measurement: measurement) { status in
            handler(status)
        }
    }
}

public class AccelerationPointRemovalCleaner: Cleaner {

    public func clean(measurement: MeasurementEntity, from persistenceLayer: PersistenceLayer, onFinishedCall handler:@escaping (Status) -> Void) {
        persistenceLayer.clean(measurement: measurement) { (status) in
            handler(status)
        }
    }
}

public enum SynchronizationError: Error {
    case reachabilityNotInitialized
}
