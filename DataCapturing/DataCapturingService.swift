//
//  DataCapturingService.swift
//  DataCapturingServices
//
//  Created by Team Cyface on 02.11.17.
//  Copyright © 2017 Cyface GmbH. All rights reserved.
//

import Foundation
import CoreMotion
import CoreLocation
import os.log
import CoreData

/**
 An object of this class handles the lifecycle of starting and stopping data capturing as well as transmitting results to an appropriate server.
 
 To avoid using the users traffic or incurring costs, the service waits for Wifi access before transmitting any data. You may however force synchronization if required, using `forceSyncU()`.
 
 An object of this class is not thread safe and should only be used once per application. Youmay start and stop the service as often as you like and reuse the object.
 
 - Author: Klemens Muthmann
 - Version: 2.0.0
 - Since: 1.0.0
 */
public class DataCapturingService: NSObject  {
    //MARK: Properties
    /// `true` if data capturing is running; `false` otherwise.
    private(set) public var isRunning: Bool
    
    /// A listener that is notified of important events during data capturing.
    private var handler: ((DataCapturingEvent) -> Void)?
    
    /// The currently recorded `Measurement` or nil if there is no active recording.
    private var currentMeasurement: MeasurementMO?
    
    /// An instance of `CMMotionManager`. There should be only one instance of this type in your application.
    private let motionManager: CMMotionManager
    
    
    /// Provides access to the devices geo location capturing hardware (such as GPS, GLONASS, GALILEO, etc.) and handles geo location updates in the background.
    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.allowsBackgroundLocationUpdates = true
        manager.activityType = .other
        manager.showsBackgroundLocationIndicator = true
        manager.distanceFilter = kCLDistanceFilterNone
        manager.requestAlwaysAuthorization()
        return manager
    }()
    
    /// An API to store, retrieve and update captured data to the local system until the App can transmit it to a server.
    private let persistenceLayer: PersistenceLayer
    
    private let serverConnection: ServerConnection
    
    //MARK: Initializers
    /**
     Creates a new completely initialized `DataCapturingService` transmitting data via the provided server connection and accessing data a certain amount of times per second.
     - Parameters:
        - serverConnection: An authenticated connection to a Cyface API server.
        - sensorManager: An instance of `CMMotionManager`. There should be only one instance of this type in your application. Since it seems to be impossible to create that instance inside a framework at the moment, you have to provide it via this parameter.
        - updateInterval: The accelerometer update interval in Hertz. By default this is set to the supported maximum of 100 Hz.
        - persistenceLayer: An API to store, retrieve and update captured data to the local system until the App can transmit it to a server.
     */
    public init(connection serverConnection: ServerConnection, sensorManager manager:CMMotionManager, updateInterval interval : Double = 100, persistenceLayer persistence: PersistenceLayer) {
        self.persistenceLayer = persistence
        isRunning = false
        self.motionManager = manager
        motionManager.accelerometerUpdateInterval = 1.0 / interval
        self.serverConnection = serverConnection
        super.init()
    }
    
    //MARK: Methods
    /// Starts the capturing process. This operation is idempotent.
    public func start() {
        guard !isRunning else {
            os_log("Trying to start DataCapturingService which is already running!")
            return
        }
        
        self.locationManager.startUpdatingLocation()
        self.isRunning = true
        let measurement = persistenceLayer.createMeasurement(at: currentTimeInMillisSince1970())
        self.currentMeasurement = measurement
        
        if(motionManager.isAccelerometerAvailable) {
            motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { data, error in
                guard let myData = data else {
                    fatalError("DataCapturingService.start(): No Accelerometer data available!")
                }
                
                let accValues = myData.acceleration
                let acc = self.persistenceLayer.createAcceleration(x: accValues.x,y: accValues.y, z: accValues.z,at: self.currentTimeInMillisSince1970())
                measurement.addToAccelerations(acc)
            }
        }
    }
    
    /**
     Starts the capturing process with a listener that is notified of important events occuring while the capturing process is running. This operation is idempotent.
     
     - Parameter handler: A listener that is notified of important events during data capturing.
     */
    public func start(withHandler handler:@escaping ((DataCapturingEvent) -> Void)) {
        self.handler = handler
        self.start()
    }
    
    /// Stops the currently running data capturing process or does nothing of the process is not running.
    public func stop() {
        isRunning = false
        motionManager.stopAccelerometerUpdates()
        locationManager.stopUpdatingLocation()
        currentMeasurement = nil
    }
    
    /// Forces the service to synchronize all Measurements now if a connection is available. If this is not called the service might wait for an opprotune moment to start synchronization.
    public func forceSync() {
        // TODO: Do we need to do anything here to ensure proper HTTPS data transmission.
        var m = self.persistenceLayer.loadMeasurement(fromPosition: 0)
        while m != nil {
            let mUnwrapped = m!
            if serverConnection.isAuthenticated() {
                serverConnection.sync(measurement: mUnwrapped)
            }
            // Cleanup
            // TODO: This can lead to upload duplicates if a measurements upload is interrupted and needs to restart later.
            self.persistenceLayer.delete(measurement: mUnwrapped)
            m = self.persistenceLayer.loadMeasurement(fromPosition: 0)
        }
        
        notify(of: .synchronizationSuccessful)
    }
    
    /// Deletes an unsynchronized `Measurement` from this device.
    public func delete(unsyncedMeasurement measurement : MeasurementMO) {
        persistenceLayer.delete(measurement: measurement)
        persistenceLayer.save()
    }
    
    public func countMeasurements() -> Int {
        return persistenceLayer.countMeasurements()
    }
    
    public func loadMeasurement(at index: Int) -> MeasurementMO? {
        return persistenceLayer.loadMeasurement(fromPosition: index)
    }
    
    /// Provides the current time in milliseconds since january 1st 1970 (UTC).
    private func currentTimeInMillisSince1970() -> Int64 {
        return convertToUtcTimestamp(date: Date())
    }
    
    /// Converts a `Data` object to a UTC milliseconds timestamp since january 1st 1970.
    private func convertToUtcTimestamp(date value: Date) -> Int64 {
        return Int64(value.timeIntervalSince1970*1000.0)
    }
    
    private func notify(of event:DataCapturingEvent) {
        guard let handler = self.handler else {
            return
        }
        
        handler(event)
    }
}

// MARK: CLLocationManagerDelegate
extension DataCapturingService: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard !locations.isEmpty else {
            fatalError("No location available for DataCapturingService!")
        }
        let location: CLLocation = locations[0]
        os_log("New location: lat %@, lon %@",type: .info, location.coordinate.latitude.description,location.coordinate.longitude.description)
        
        guard let measurement = currentMeasurement else {
            fatalError("No current measurement to save the location to! Data capturing impossible.")
        }
        let geoLocation = persistenceLayer.createGeoLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, accuracy: location.horizontalAccuracy, speed: location.speed, at: convertToUtcTimestamp(date: location.timestamp))
        measurement.addToGeoLocations(geoLocation)
        notify(of: .geoLocationAcquired(position: geoLocation))
        
        persistenceLayer.save()
    }
}
// TODO: Add support for different vehicles
// TODO: Transform DataCapturingListener to Closure
