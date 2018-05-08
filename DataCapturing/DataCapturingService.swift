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
public class DataCapturingService: NSObject, MeasurementLifecycle {

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
    private var currentMeasurement: MeasurementMO?

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

    // MARK: Initializers
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

        // TODO: Do we really need to call forceSync twice here and 6 lines below.
        forceSync {[unowned self] in
            self.notify(of: .synchronizationSuccessful)
        }
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

    // MARK: Methods
    /**
     Starts the capturing process with an optional closure, that is notified of important events
     during the capturing process. This operation is idempotent.
     
      - Parameter handler: A closure that is notified of important events during data capturing.
      - Return: The measurement created by this call to `start`.
     */
    public func start(withHandler handler: @escaping ((DataCapturingEvent) -> Void) = {_ in }) -> MeasurementMO {
        guard !isPaused else {
            fatalError("DataCapturingService.start(): Invalid state! You tried to start the data capturing service in paused state! Please call resume() and stop() before starting the service!")
        }

        let measurement = persistenceLayer.createMeasurement(at: currentTimeInMillisSince1970())
        measurement.synchronized = false
        self.currentMeasurement = measurement

        startCapturing(withHandler:handler)
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
        let measurements = self.persistenceLayer.loadMeasurements()
        var countOfMeasurementsToSynchronize = measurements.count
        for measurement in measurements {
            if serverConnection.isAuthenticated(), reachabilityManager.isReachableOnEthernetOrWiFi {
                // In case no handler was provided simply use an empty one.
                let syncFinishedHandler: ((MeasurementMO, ServerConnectionError?)->Void) = {[unowned self] measurement, error in
                    // Only go on if there was no error
                    guard error==nil else {
                        os_log("Unable to upload data for measurement: %@!",measurement.identifier)
                        return
                    }
                    self.cleanDataAfterSync(for: measurement)

                    // Inform UI if interested
                    if let syncDelegate = self.syncDelegate {
                        let currentIdentifier = measurement.identifier
                        DispatchQueue.main.async {
                            syncDelegate(currentIdentifier)
                        }
                    }

                    // TODO: synchronize this?
                    countOfMeasurementsToSynchronize -= 1

                    // Everything synchronized
                    if countOfMeasurementsToSynchronize == 0 {
                        handler()
                        if self.countMeasurements()==0 {
                            self.reachabilityManager.stopListening()
                        }
                    }
                }
                serverConnection.sync(measurement: measurement, onFinish: syncFinishedHandler)
            }
        }
        // TODO: Synchronization is not necessarily successful at this point. It might not even be finished.

    }

    func cleanDataAfterSync(for measurement: MeasurementMO) {
        // Delete measurement
        // TODO: This runs not on the main thread and requires a different context.
        self.persistenceLayer.delete(measurement: measurement)
    }

    /**
     Deletes a `Measurement` from this device.
 
     - Parameter measurement: The `Measurement` to delete. You can get this for example via
        `loadMeasurement(index:)`.
    */
    public func delete(measurement: MeasurementMO) {
        persistenceLayer.delete(measurement: measurement)
    }

    /// Provides the amount of `Measurements` currently cached by the system.
    public func countMeasurements() -> Int {
        return persistenceLayer.countMeasurements()
    }

    /**
     Provides the cached `Measurement` with the provided `identifier`.
     
     - Parameter identifier: A measurement identifier to load the measurement for.
     */
    public func loadMeasurement(withIdentifier identifier: Int64) -> MeasurementMO? {
        return persistenceLayer.loadMeasurement(withIdentifier: identifier)
    }

    /// Loads all currently cached `Measurement` instances.
    public func loadMeasurements() -> [MeasurementMO] {
        return persistenceLayer.loadMeasurements()
    }

    /// Provides the current time in milliseconds since january 1st 1970 (UTC).
    private func currentTimeInMillisSince1970() -> Int64 {
        return convertToUtcTimestamp(date: Date())
    }

    /// Converts a `Data` object to a UTC milliseconds timestamp since january 1st 1970.
    private func convertToUtcTimestamp(date value: Date) -> Int64 {
        return Int64(value.timeIntervalSince1970*1000.0)
    }

    func startCapturing(withHandler handler: @escaping ((DataCapturingEvent) -> Void) = {_ in }) {
        // Preconditions
        guard let currentMeasurement = currentMeasurement else {
            fatalError("DataCapturingService.startCapturing(): Trying to start data capturing without a measurement.")
        }
        guard !isRunning else {
            os_log("DataCapturingService.startCapturing(): Trying to start DataCapturingService which is already running!", log: LOG, type: .info)
            return
        }

        self.handler = handler
        self.locationManager.delegate = self
        self.locationManager.startUpdatingLocation()

        if motionManager.isAccelerometerAvailable {
            motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { data, _ in
                guard let myData = data else {
                    fatalError("DataCapturingService.start(): No Accelerometer data available!")
                }

                let accValues = myData.acceleration
                let acc = self.persistenceLayer.createAcceleration(
                    x: accValues.x,
                    y: accValues.y,
                    z: accValues.z,
                    at: self.currentTimeInMillisSince1970())
                currentMeasurement.addToAccelerations(acc)
            }
        }

        isRunning = true
    }

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
     
     - Parameter event: The `event` to notify the `handler` of.
     */
    private func notify(of event: DataCapturingEvent) {
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
        os_log("New location: lat %@, lon %@", type: .info, location.coordinate.latitude.description, location.coordinate.longitude.description)

        guard let measurement = currentMeasurement else {
            fatalError("No current measurement to save the location to! Data capturing impossible.")
        }
        let geoLocation = persistenceLayer.createGeoLocation(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            accuracy: location.horizontalAccuracy,
            speed: location.speed,
            at: convertToUtcTimestamp(date: location.timestamp))
        measurement.addToGeoLocations(geoLocation)
        notify(of: .geoLocationAcquired(position: geoLocation))

        persistenceLayer.save()
    }
}
