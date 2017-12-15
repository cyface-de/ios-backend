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
    private var listener: DataCapturingListener?
    
    /// The currently recorded `Measurement` or nil if there is no active recording.
    private var currentMeasurement: MeasurementMO?
    
    /// An instance of `CMMotionManager`. There should be only one instance of this type in your application.
    private let motionManager: CMMotionManager
    
    /// Session object to upload captured data to a Cyface server.
    private lazy var apiSession: URLSession = {
        return URLSession()
    }()
    
    /// A `URL` used to upload data to. There should be a server complying to a Cyface REST interface available at that location.
    private let cyfaceEndpoint: URL
    
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
    
    /// Encoder used to format measurements into processable JSON for a Cyface server.
    private lazy var uploadMessagesEncoder = JSONEncoder()
    
    
    //MARK: Initializers
    /**
     Creates a new completely initialized `DataCapturingService` transmitting data to a provided endpoint and accessing data a certain amount of times per second.
     - Parameters:
     - dataEndpoint: A `URL` used to upload data to. There should be a server complying to a Cyface REST interface available at that location.
     - sensorManager: An instance of `CMMotionManager`. There should be only one instance of this type in your application. Since it seems to be impossible to create that instance inside a framework at the moment, you have to provide it via this parameter.
     - updateInterval: The accelerometer update interval in Hertz. By default this is set to the supported maximum of 100 Hz.
     - persistenceLayer: An API to store, retrieve and update captured data to the local system until the App can transmit it to a server.
     */
    public init(dataEndpoint endpoint: URL, sensorManager manager:CMMotionManager, updateInterval interval : Double = 100, persistenceLayer persistence: PersistenceLayer) {
        //unsyncedMeasurements = [] // TODO init persistence layer here and load unsynced measurements
        self.persistenceLayer = persistence
        isRunning = false
        self.motionManager = manager
        motionManager.accelerometerUpdateInterval = 1.0 / interval
        self.cyfaceEndpoint = endpoint
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
                    fatalError("No Accelerometer data available!")
                }
                
                let accValues = myData.acceleration
                //let eventDate = NSDate(timeInterval: myData.timestamp, sinceDate: bootTime)
                let acc = self.persistenceLayer.createAcceleration(x: accValues.x,y: accValues.y, z: accValues.z,at: self.currentTimeInMillisSince1970())
                measurement.addToAccelerations(acc)
            }
        }
    }
    
    /**
     Starts the capturing process with a listener that is notified of important events occuring while the capturing process is running. This operation is idempotent.
     
     - Parameter listener: A listener that is notified of important events during data capturing.
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
        // TODO: Do we need to do anything here to ensure proper HTTPS data transmission.
        let authenticationTask = apiSession.dataTask(with: cyfaceEndpoint.appendingPathComponent("login")) { data, response, error in
            if let error = error {
                os_log("Unable to authenticate due to %@", error.localizedDescription)
                return
            }
            let data = data!
            
            guard let unwrappedResponse = response as? HTTPURLResponse, unwrappedResponse.statusCode == 200 else {
                os_log("Unable to authenticate.")
                return
            }
            
            if unwrappedResponse.mimeType=="application/json" {
                let jwtBearer = String (data: data, encoding: .utf8)
                var request = URLRequest(url: self.cyfaceEndpoint.appendingPathComponent("measurements"))
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue(jwtBearer,forHTTPHeaderField: "Authorization")
                
                var m = self.persistenceLayer.loadMeasurement(fromPosition: 0)
                while m != nil {
                    let mUnwrapped = m!
                    let chunks = self.makeUploadChunks(fromMeasurement: mUnwrapped)
                    for chunk in chunks {
                        guard let jsonChunk = try? self.uploadMessagesEncoder.encode(chunk) else {
                            fatalError("Invalid measurement format.")
                        }
                        
                        let submissionTask = self.apiSession.uploadTask(with: request, from: jsonChunk) { data, response, error in
                            if let error = error {
                                os_log("Server Error during upload of measurement %@! Encountered errror %@.", mUnwrapped, error.localizedDescription )
                                return
                            }
                            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                                os_log("Client Error during upload of measurement %@!",mUnwrapped)
                                return
                            }
                        }
                        
                        submissionTask.resume()
                    }
                    // Cleanup
                    // TODO: This can lead to upload duplicates if a measurements upload is interrupted and needs to restart later.
                    self.persistenceLayer.delete(measurement: mUnwrapped)
                    m = self.persistenceLayer.loadMeasurement(fromPosition: 0)
                }
                
            }
        }
        authenticationTask.resume()
    }
    
    /// Deletes an unsynchronized `Measurement` from this device.
    public func delete(unsyncedMeasurement measurement : MeasurementMO) {
        persistenceLayer.delete(measurement: measurement)
    }
    
    private func makeUploadChunks(fromMeasurement measurement: MeasurementMO) -> [String:Encodable] {
        // TODO: Not really chunked yet. Still loads everything into main memory.
        var geoLocations = [[String:Any]]()
        if let measurementLocations = measurement.geoLocations {
            for location in measurementLocations {
                let location = location as! GeoLocationMO
                geoLocations.append(["\"lat\"":location.lat,"\"lon\"":location.lon,"\"speed\"":location.speed,"\"timestamp\"":location.timestamp,"\"accuracy\"":location.accuracy])
            }
        }
        
        var accelerationPoints = [[String:Encodable]]()
        if let accelerations = measurement.accelerations {
            for acceleration in accelerations {
                let acceleration = acceleration as! AccelerationPointMO
                accelerationPoints.append(["\"ax\"":acceleration.ax,"\"ay\"":acceleration.ay,"\"az\"":acceleration.az,"\"timestamp\"":acceleration.timestamp])
            }
        }
        
        return ["\"deviceId\"":"\"\(deviceId)\"","\"id\"":measurement.identifier,"\"vehicle\"":"\"BICYCLE\"","\"gpsPoints\"":geoLocations,"\"accelerationPoints\"":accelerationPoints]
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
        let geoLocation = persistenceLayer.createGeoLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, accuracy: location.horizontalAccuracy, speed: location.speed, at: convertToUtcTimestamp(date: location.timestamp))
        measurement.addToGeoLocations(geoLocation)
        
        
        persistenceLayer.save()
    }
}
// TODO: Maybe move out the data transmission part to its own class. This seems to be mingled up here with the data capturing part.
// TODO: Fill model objects with appropriate identifiers.
// TODO: Add support for different vehicles
