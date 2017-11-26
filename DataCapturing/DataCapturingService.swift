//
//  DataCapturingService.swift
//  DataCapturingServices
//
//  Created by Team Cyface on 02.11.17.
//  Copyright © 2017 Cyface GmbH. All rights reserved.
//

import Foundation
import CoreMotion

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
    private(set) public var isRunning:Bool
    /**
     A listener that is notified of important events during data capturing.
     */
    private var listener:DataCapturingListener?
    /**
     A poor mans data storage.
     
     This is only in memory and will be replaced by a database on persistent storage during final implementation.
     */
    private(set) public var unsyncedMeasurements:[Measurement]
    /**
     An instance of `CMMotionManager`. There should be only one instance of this type in your application.
    */
    private let motionManager : CMMotionManager
    
    //MARK: Initializers
    /**
     Creates a new completely initialized `DataCapturingService`.
     - parameters:
         - motionManager: An instance of `CMMotionManager`. There should be only one instance of this type in your application. Since it seems to be impossible to create that instance inside a framework at the moment, you have to provide it via this parameter.
         - interval: The accelerometer update interval in Hertz.
     */
    public init(withManager motionManager:CMMotionManager, andUpdateInterval interval : Double) {
        unsyncedMeasurements = []
        isRunning = false
        self.motionManager = motionManager
        motionManager.accelerometerUpdateInterval = 1.0 / interval
    }
    
    //MARK: Methods
    /**
     Starts the capturing process. This operation is idempotent.
     */
    public func start() {
        isRunning = true
        let m = Measurement(Int64(unsyncedMeasurements.count))
        unsyncedMeasurements.append(m)

        if(motionManager.isAccelerometerAvailable) {
            motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { data, error in
                if let myData = data {
                    let accValues = myData.acceleration
                    //let eventDate = NSDate(timeInterval: myData.timestamp, sinceDate: bootTime)
                    let acc = AccelerationPoint(id: nil, ax: accValues.x,ay: accValues.y, az: accValues.z,timestamp: self.currentTimeInMillisSince1970())
                    m.append(acc)
                }
            }
        }
    }
    
    /**
     Starts the capturing process with a listener that is notified of important events occuring while the capturing process is running. This operation is idempotent.
     
     - parameters:
     - listener: A listener that is notified of important events during data capturing.
     */
    public func start(with listener:DataCapturingListener) {
        self.listener = listener
        self.start()
    }
    
    /**
     Stops the currently running data capturing process or does nothing of the process is not running.
     */
    public func stop() {
        isRunning = false
        motionManager.stopAccelerometerUpdates()
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
    
    /**
     Provides the current time in milliseconds since 1st january 1970 (UTC).
    */
    private func currentTimeInMillisSince1970() -> Int64 {
        return Int64(Date().timeIntervalSince1970*1000.0)
    }
    
}
