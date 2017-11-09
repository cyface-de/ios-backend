//
//  DataCapturingService.swift
//  DataCapturingServices
//
//  Created by Team Cyface on 02.11.17.
//  Copyright © 2017 Cyface GmbH. All rights reserved.
//

import Foundation

/**
 An object of this class handles the lifecycle of starting and stopping data capturing as well as transmitting results to an appropriate server.
 
 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 1.0.0
 
 To avoid using the users traffic or incurring costs, the service waits for Wifi access before transmitting any data. You may however force synchronization if required, using `forceSyncU()`.
 
 An object of this class is not thread safe and should only be used once per application. Youmay start and stop the service as often as you like and reuse the object.
 */
public class DataCapturingService {
    //MARK: Properties
    /**
     `true` if data capturing is running; `false` otherwise.
     */
    private(set) var isRunning:Bool
    /**
     A listener that is notified of important events during data capturing.
     */
    private var listener:DataCapturingListener?
    /**
     A poor mans data storage.
     
     This is only in memory and will be replaced by a database on persistent storage during final implementation.
     */
    private(set) var unsyncedMeasurements:[Measurement]
    
    //MARK: Initializers
    /**
     Creates a new completely initialized `DataCapturingService`.
     */
    public init() {
        unsyncedMeasurements = []
        isRunning = false
    }
    
    //MARK: Methods
    /**
     Starts the capturing process. This operation is idempotent.
     */
    public func start() {
        isRunning = true
        unsyncedMeasurements.append(Measurement())
    }
    
    /**
     Starts the capturing process with a listener that is notified of important events occuring while the capturing process is running. This operation is idempotent.
     
     - parameters:
     - listener: A listener that is notified of important events during data capturing.
     */
    public func start(with listener:DataCapturingListener) {
        self.listener = listener
    }
    
    /**
     Stops the currently running data capturing process or does nothing of the process is not running.
     */
    public func stop() {
        isRunning = false
    }
    
    /**
     Forces the service to synchronize all Measurements now if a connection is available. If this is not called the service might wait for an opprotune moment to start synchronization.
     */
    public func forceSync() {
        unsyncedMeasurements.removeAll()
    }
    
    /**
     Deletes an unsynchronized `Measurement` from this device.
     */
    public func delete(unsynced measurement : Measurement) {
        guard let index = unsyncedMeasurements.index(of:measurement) else {
            return
        }
        unsyncedMeasurements.remove(at:index)
    }
}
