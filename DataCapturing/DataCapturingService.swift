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
import Alamofire

/**
 An object of this class handles the lifecycle of starting and stopping data capturing as well as
 transmitting results to an appropriate server.
 
 To avoid using the users traffic or incurring costs, the service waits for Wifi access before
 transmitting any data. You may however force synchronization if required, using
 `forceSync(onFinish:)`.
 
 An object of this class is not thread safe and should only be used once per application. You may
 start and stop the service as often as you like and reuse the object.
 
 - Author: Klemens Muthmann
 - Version: 3.0.0
 - Since: 1.0.0
 */
public class DataCapturingService: NSObject {

    // MARK: - Properties
    /// Data used to identify log messages created by this component.
    private let LOG = OSLog(subsystem: "de.cyface", category: "DataCapturingService")

    /// `true` if data capturing is running; `false` otherwise.
    public var isRunning: Bool

    /// `true` if data capturing was running but is currently paused; `false` otherwise.
    public var isPaused: Bool

    /// A listener that is notified of important events during data capturing.
    private var handler: ((DataCapturingEvent) -> Void)?

    /// The currently recorded `Measurement` or nil if there is no active recording.
    private var currentMeasurement: MeasurementEntity?

    /// An instance of `CMMotionManager`. There should be only one instance of this type in your application.
    private let motionManager: CMMotionManager

    /**
     Provides access to the devices geo location capturing hardware (such as GPS, GLONASS, GALILEO, etc.)
     and handles geo location updates in the background.
     */
    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        manager.activityType = .other
        manager.showsBackgroundLocationIndicator = true
        manager.distanceFilter = kCLDistanceFilterNone
        manager.requestAlwaysAuthorization()
        return manager
    }()

    /**
     An API to store, retrieve and update captured data to the local system until the App
     can transmit it to a server.
     */
    let persistenceLayer: PersistenceLayer

    /// An API that handles authentication and communication with a Cyface server.
    private let serverConnection: ServerConnection

    /// Handles background synchronization of available `Measurement`s.
    let reachabilityManager: NetworkReachabilityManager

    /**
     A delegate that is informed about successful measurement synchronization.
     Gets the synchronized measurements identifer as parameter.
     This can be used to synchronize view elements showing measurements with the corresponding
     measurement and refresh upon deletion.
     */
    public var syncDelegate: ((Int64) -> Void)?

    /**
     A flag indicating whether synchronization of data should only happen if the device is connected to a wireless local area network (Wifi).

     If `true` data is only synchronized via Wifi; if `false` data is also synchronized via mobile network.
     The default setting is `true`.
     Setting this to `false` might put heavy load on the users device and deplete her or his data plan.
     */
    public var syncOnWiFiOnly: Bool

    /// An in memory storage for accelerations, before they are written to disk.
    private var accelerationsCache = [Acceleration]()

    /// The background queue used to capture data.
    private let capturingQueue = DispatchQueue.global(qos: .userInitiated)

    // MARK: - Initializers
    /**
     Creates a new completely initialized `DataCapturingService` transmitting data
     via the provided server connection and accessing data a certain amount of times per second.
     - Parameters:
     - serverConnection: An authenticated connection to a Cyface API server.
     - sensorManager: An instance of `CMMotionManager`.
     There should be only one instance of this type in your application.
     Since it seems to be impossible to create that instance inside a framework at the moment,
     you have to provide it via this parameter.
     - updateInterval: The accelerometer update interval in Hertz. By default this is set to the supported maximum of 100 Hz.
     - persistenceLayer: An API to store, retrieve and update captured data to the local system until the App can transmit it to a server.
     */
    public init(
        connection serverConnection: ServerConnection,
        sensorManager manager: CMMotionManager,
        updateInterval interval: Double = 100,
        persistenceLayer persistence: PersistenceLayer) {

        self.isRunning = false
        self.isPaused = false
        self.persistenceLayer = persistence
        self.motionManager = manager
        motionManager.accelerometerUpdateInterval = 1.0 / interval
        self.serverConnection = serverConnection

        self.syncOnWiFiOnly = true
        guard let reachabilityManager = NetworkReachabilityManager(host: serverConnection.getURL().absoluteString) else {
            fatalError("Unable to initialize reachability manager.")
        }
        self.reachabilityManager = reachabilityManager
        super.init()

        self.reachabilityManager.listener = {
            [unowned self] status in
            let reachable = self.syncOnWiFiOnly ?  status == NetworkReachabilityManager.NetworkReachabilityStatus.reachable(.ethernetOrWiFi) : status == NetworkReachabilityManager.NetworkReachabilityStatus.reachable(.wwan) || status == NetworkReachabilityManager.NetworkReachabilityStatus.reachable(.ethernetOrWiFi)

            if reachable {
                self.forceSync {
                    self.notify(of: .synchronizationSuccessful)
                }
            }
        }
        self.reachabilityManager.startListening()
    }

    // MARK: - Methods
    /**
     Starts the capturing process with an optional closure, that is notified of important events
     during the capturing process. This operation is idempotent.
     
     - Parameter handler: A closure that is notified of important events during data capturing.
     - Return: A `MeasurementEntity` as representation of the measurement created by this call to `start`.
     */
    public func start(inContext context: MeasurementContext, withHandler handler: @escaping ((DataCapturingEvent) -> Void) = {_ in }) -> MeasurementEntity {
        guard !isPaused else {
            fatalError("DataCapturingService.start(): Invalid state! You tried to start the data capturing service in paused state! Please call resume() and stop() before starting the service!")
        }

        let measurement = persistenceLayer.createMeasurement(at: currentTimeInMillisSince1970(), withContext: context)
        self.currentMeasurement = measurement

        startCapturing(withHandler: handler)
        return measurement
    }

    /**
     Stops the currently running data capturing process or does nothing if the process is not
     running.
     */
    public func stop() {
        guard !isPaused else {
            fatalError("DataCapturingService.stop(): Invalid state! You tried to stop the data capturing service in paused state! Please call resume() prior to stop()!")
        }

        stopCapturing()
        currentMeasurement = nil
        reachabilityManager.startListening()
    }

    /**
     Pauses the current data capturing measurement for the moment. No data is captured until `resume()` has been called, but upon the call to `resume()` the last measurement will be continued instead of beginning a new now. After using `pause()` you must call resume before you can call any other lifecycle method like `stop()`, for example.
     */
    public func pause() {
        guard isRunning, !isPaused else {
            fatalError("DataCapturingService.pause(): isPaused --> \(isPaused), isRunning --> \(isRunning)")
        }

        stopCapturing()
        isPaused = true
    }

    /**
     Resumes the current data capturing with the data capturing measurement that was running when `pause()` was called. A call to this method is only valid after a call to `pause()`. It is going to fail if used after `start()` or `stop()`.

     - Parameter handler: The handler receiving `DataCapturingEvent` instances from the resumed capturing.
     */
    public func resume(withHandler handler: @escaping ((DataCapturingEvent) -> Void) = {_ in }) {
        guard isPaused, !isRunning else {
            fatalError("DataCapturingService.resume(): isPaused --> \(isPaused), isRunning --> \(isRunning)")
        }

        startCapturing(withHandler: handler)
        isPaused = false
    }

    /**
     Forces the service to synchronize all Measurements now if a connection is available.
     If this is not called the service might wait for an opportune moment to start synchronization.

     - Parameter onFinish: A handler called each time a synchronization has finished.
     */
    public func forceSync(onFinish handler: @escaping (() -> Void)) {
        if !self.serverConnection.isAuthenticated() || !self.reachabilityManager.isReachableOnEthernetOrWiFi {
            // Quit directly.
            handler()
        }

        self.persistenceLayer.loadMeasurements { [unowned self] measurements in
            var countOfMeasurementsToSynchronize = measurements.count
            guard countOfMeasurementsToSynchronize>0 else {
                handler()
                return;
            }

            for measurement in measurements {
                let synchronizationFinishedHandler: (MeasurementEntity, ServerConnectionError?) -> Void = { [unowned self] measurement, error in
                    // Only go on if there was no error
                    if error == nil {
                        self.cleanDataAfterSync(for: measurement) {
                            // Inform UI if interested
                            if let syncDelegate = self.syncDelegate {
                                DispatchQueue.main.async {
                                    syncDelegate(measurement.identifier)
                                }
                            }
                        }
                    } else {
                        os_log("Unable to upload data for measurement: %@!", NSNumber(value: measurement.identifier))
                    }
                    // TODO: synchronize this?
                    countOfMeasurementsToSynchronize -= 1

                    // Everything uploaded?
                    if countOfMeasurementsToSynchronize == 0 {
                        handler()
                        if self.countMeasurements()==0 {
                            self.reachabilityManager.stopListening()
                        }
                    }
                }
                if let measurementContext = MeasurementContext(rawValue: measurement.context) {
                    self.serverConnection.sync(measurement: MeasurementEntity(identifier: measurement.identifier, context: measurementContext), onFinishedCall: synchronizationFinishedHandler)
                }
            }
        }
    }

    /**
     Cleans the database after a measurement has been synchronized.

     - Parameters:
     - measurement: The measurement to clean.
     - handler: Called as soon as deletion has finished.
     */
    func cleanDataAfterSync(for measurement: MeasurementEntity, onFinished handler: @escaping (() -> Void)) {
        persistenceLayer.delete(measurement: measurement, onFinishedCall: handler)
    }

    /**
     Deletes a `Measurement` from this device.

     - Parameter measurement: The `Measurement` to delete. You can get this for example via
     `loadMeasurement(index:)`.
     */
    public func delete(measurement: MeasurementEntity, andCallWhenFinished finishedHandler: @escaping () -> Void) {
        persistenceLayer.delete(measurement: measurement, onFinishedCall: finishedHandler)
    }

    /// Provides the amount of `Measurements` currently cached by the system.
    public func countMeasurements() -> Int {
        var ret: Int?
        let syncGroup = DispatchGroup()
        syncGroup.enter()
        persistenceLayer.countMeasurements { count in
            ret = count
            syncGroup.leave()
        }
        guard syncGroup.wait(timeout: DispatchTime.now() + .seconds(2)) == .success else {
            fatalError("DataCapturingService.countMeasurements(): Unable to count measurements.")
        }
        return ret!
    }

    /**
     Provides the cached `Measurement` with the provided `identifier`.
     
     - Parameter identifier: A measurement identifier to load the measurement for.
     - Returns: The loaded `MeasurementEntity`
     */
    public func loadMeasurement(withIdentifier identifier: Int64) -> MeasurementEntity? {
        var ret: MeasurementEntity?
        let syncGroup = DispatchGroup()
        syncGroup.enter()
        persistenceLayer.load(measurementIdentifiedBy: identifier) { measurement in
            if let measurementContext = MeasurementContext(rawValue: measurement.context) {
                ret = MeasurementEntity(identifier: measurement.identifier, context: measurementContext)
            }
            syncGroup.leave()
        }
        guard syncGroup.wait(timeout: DispatchTime.now() + .seconds(2)) == .success else {
            fatalError("DataCapturingService.loadMeasurement(withIdentifier: \(identifier)): Unable to load measurement!")
        }
        return ret
    }

    /**
     Loads all currently cached `Measurement` instances.

     - Returns: The array of loaded `MeasurementEntity` objects.
     */
    public func loadMeasurements() -> [MeasurementEntity] {
        var ret = [MeasurementEntity]()
        let syncGroup = DispatchGroup()
        syncGroup.enter()
        persistenceLayer.loadMeasurements { measurements in
            measurements.forEach({ [unowned self] (measurement) in
                if measurement.identifier != self.currentMeasurement?.identifier, let measurementContext = MeasurementContext(rawValue: measurement.context) {
                    ret.append(MeasurementEntity(identifier: measurement.identifier, context: measurementContext))
                }
            })
            syncGroup.leave()
        }
        guard syncGroup.wait(timeout: DispatchTime.now() + .seconds(2)) == .success else {
            fatalError("DataCapturingService.loadMeasurements(): Unable to load measurements!")
        }
        return ret
    }

    /**
     Loads all the geo locations belonging to a certain measurement.

     - Parameters:
     - belongingTo: The measurement the geo locations are to be loaded for.
     - onFinished: The handler called after finishing loading the geo locations. The loaded locations are provided as an array to this handler.
     */
    public func loadGeoLocations(belongingTo measurement: MeasurementEntity, onFinished handler: @escaping ([GeoLocation]) -> Void) {
        persistenceLayer.load(measurementIdentifiedBy: measurement.identifier) { measurement in
            var ret = [GeoLocation]()
            measurement.geoLocations.forEach({ (location) in
                ret.append(GeoLocation(latitude: location.lat, longitude: location.lon, accuracy: location.accuracy, speed: location.speed, timestamp: location.timestamp))
            })
            handler(ret)
        }
    }

    /**
     Loads all the accelerations belonging to a certain measurement.

     - Parameters:
     - belongingTo: The measurement the accelerations are to be loaded for.
     - onFinished: The handler called after finishing loading the accelerations. The loaded accelerations are provided as an array to this handler.
     */
    public func loadAccelerations(belongingTo measurement: MeasurementEntity, onFinished handler: @escaping ([Acceleration]) -> Void) {
        persistenceLayer.load(measurementIdentifiedBy: measurement.identifier) { (measurement) in
            var ret = [Acceleration]()
            measurement.accelerations.forEach({ (acceleration) in
                ret.append(Acceleration(timestamp: acceleration.timestamp, x: acceleration.ax, y: acceleration.ay, z: acceleration.az))
            })
            handler(ret)
        }
    }

    /// Provides the current time in milliseconds since january 1st 1970 (UTC).
    private func currentTimeInMillisSince1970() -> Int64 {
        return convertToUtcTimestamp(date: Date())
    }

    /// Converts a `Data` object to a UTC milliseconds timestamp since january 1st 1970.
    private func convertToUtcTimestamp(date value: Date) -> Int64 {
        return Int64(value.timeIntervalSince1970*1000.0)
    }

    /**
     Internal method for starting the capturing process. This can optionally take in a handler for events occuring during data capturing.

     - Parameter withHandler: An optional handler used by the capturing process to inform about `DataCapturingEvent`s.
     */
    func startCapturing(withHandler handler: @escaping ((DataCapturingEvent) -> Void) = {_ in }) {
        // Preconditions
        guard !isRunning else {
            os_log("DataCapturingService.startCapturing(): Trying to start DataCapturingService which is already running!", log: LOG, type: .info)
            return
        }

        self.handler = handler
        self.locationManager.delegate = self
        self.locationManager.startUpdatingLocation()

        let queue = OperationQueue()
        queue.qualityOfService = QualityOfService.userInitiated
        queue.underlyingQueue = capturingQueue
        if motionManager.isAccelerometerAvailable {
            motionManager.startAccelerometerUpdates(to: queue) { [unowned self] data, _ in
                guard let myData = data else {
                    fatalError("DataCapturingService.start(): No Accelerometer data available!")
                }

                let accValues = myData.acceleration
                let acc = Acceleration(timestamp: self.currentTimeInMillisSince1970(),
                                       x: accValues.x,
                                       y: accValues.y,
                                       z: accValues.z)
                self.accelerationsCache.append(acc)
            }
        }

        isRunning = true
    }

    /**
     An internal helper method for stopping the capturing process.
     */
    func stopCapturing() {
        guard isRunning else {
            os_log("Trying to stop a non running service!", log: LOG, type: .info)
            return
        }

        motionManager.stopAccelerometerUpdates()
        locationManager.stopUpdatingLocation()
        locationManager.delegate = nil
        isRunning = false
    }

    /**
     Calls the event `handler` if there is one. Otherwise the call is ignored silently.
     
     - Parameter of: The `event` to notify the `handler` of.
     */
    private func notify(of event: DataCapturingEvent) {
        guard let handler = self.handler else {
            return
        }

        handler(event)
    }
}

// MARK: - CLLocationManagerDelegate
/**
 Extension making a `CLLocationManagerDelegate` out of the `DataCapturingService`. This adds the capability of listining for geo location changes.
 */
extension DataCapturingService: CLLocationManagerDelegate {

    /**
     The listener method that is informed about new geo locations.

     - Parameters:
     - manager: The location manager used.
     - didUpdateLocation: An array of the updated locations.
     */
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        guard !locations.isEmpty else {
            fatalError("No location available for DataCapturingService!")
        }
        let location: CLLocation = locations[0]
        // os_log("New location: lat %@, lon %@", type: .info, location.coordinate.latitude.description, location.coordinate.longitude.description)

        guard let measurement = currentMeasurement else {
            fatalError("No current measurement to save the location to! Data capturing impossible.")
        }
        let geoLocation = GeoLocation(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            accuracy: location.horizontalAccuracy,
            speed: location.speed,
            timestamp: convertToUtcTimestamp(date: location.timestamp))

        // debugPrint("Saving \(accelerationsCache.count) accelerations")
        persistenceLayer.save(toMeasurement: measurement, location: geoLocation, accelerations: accelerationsCache) {
            self.capturingQueue.sync {
                self.accelerationsCache.removeAll()
                DispatchQueue.main.async {
                    self.notify(of: .geoLocationAcquired(position: geoLocation))
                }
            }
        }
    }
}
