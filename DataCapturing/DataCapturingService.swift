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
    private var listener: DataCapturingListener?
    
    /// The currently recorded `Measurement` or nil if there is no active recording.
    private var currentMeasurement: Measurement?
    
    /// An instance of `CMMotionManager`. There should be only one instance of this type in your application.
    private let motionManager: CMMotionManager
    
    ///
    private lazy var dataUploadSession: URLSession = {
        return URLSession()
    }()
    
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
    
    //MARK: Initializers
    /**
     Creates a new completely initialized `DataCapturingService` transmitting data to a provided endpoint and accessing data a certain amount of times per second.
     - Parameters:
     - dataEndpoint: A `URL` used to upload data to. There should be a server complying to a Cyface REST interface available at that location.
     - sensorManager: An instance of `CMMotionManager`. There should be only one instance of this type in your application. Since it seems to be impossible to create that instance inside a framework at the moment, you have to provide it via this parameter.
     - updateInterval: The accelerometer update interval in Hertz. By default this is set to the supported maximum of 100 Hz.
     */
    public init(dataEndpoint endpoint: URL, sensorManager manager:CMMotionManager, updateInterval interval : Double = 100) {
        unsyncedMeasurements = []
        isRunning = false
        self.motionManager = manager
        motionManager.accelerometerUpdateInterval = 1.0 / interval
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
        let measurement = Measurement(Int64(unsyncedMeasurements.count))
        self.currentMeasurement = measurement
        self.unsyncedMeasurements.append(measurement)
        
        if(motionManager.isAccelerometerAvailable) {
            motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { data, error in
                guard let myData = data else {
                    fatalError("No Accelerometer data available!")
                }
                
                let accValues = myData.acceleration
                //let eventDate = NSDate(timeInterval: myData.timestamp, sinceDate: bootTime)
                let acc = AccelerationPoint(id: nil, ax: accValues.x,ay: accValues.y, az: accValues.z,timestamp: self.currentTimeInMillisSince1970())
                measurement.append(acc)
            }
        }
    }
    
    /**
     Starts the capturing process with a listener that is notified of important events occuring while the capturing process is running. This operation is idempotent.
     
     - Parameters:
     - listener: A listener that is notified of important events during data capturing.
     */
    public func start(with listener:DataCapturingListener) {
        self.listener = listener
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
        unsyncedMeasurements.removeAll()
        let url
    }
    
    /// Deletes an unsynchronized `Measurement` from this device.
    public func delete(unsynced measurement : Measurement) {
        guard let index = unsyncedMeasurements.index(of:measurement) else {
            return
        }
        unsyncedMeasurements.remove(at:index)
    }
    
    /// Provides the current time in milliseconds since january 1st 1970 (UTC).
    private func currentTimeInMillisSince1970() -> Int64 {
        return convertToUtcTimestamp(date: Date())
    }
    
    /// Converts a `Data` object to a UTC milliseconds timestamp since january 1st 1970.
    private func convertToUtcTimestamp(date value: Date) -> Int64 {
        return Int64(value.timeIntervalSince1970*1000.0)
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
        measurement.append(GeoLocation(lat: location.coordinate.latitude,lon: location.coordinate.longitude,speed: location.speed,accuracy: location.horizontalAccuracy,timestamp: convertToUtcTimestamp(date: location.timestamp)))
    }
}
// TODO: Maybe move out the data transmission part to its own class. This seems to be mingled up here with the data capturing part.
