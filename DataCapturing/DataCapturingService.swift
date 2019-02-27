/*
 * Copyright 2017 Cyface GmbH
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
import CoreMotion
import CoreLocation
import os.log

/**
 An object of this class handles the lifecycle of starting and stopping data capturing as well as transmitting results to an appropriate server.
 
 To avoid using the users traffic or incurring costs, the service waits for Wifi access before transmitting any data. You may however force synchronization if required, using the provides `Synchronizer`.
 
 An object of this class is not thread safe and should only be used once per application. You may start and stop the service as often as you like and reuse the object.
 
 - Author: Klemens Muthmann
 - Version: 6.0.0
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
    private var handler: ((DataCapturingEvent, Status) -> Void)

    /// The currently recorded `Measurement` or `nil` if there is no active recording.
    public var currentMeasurement: MeasurementEntity?

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

    /// An in memory storage for accelerations, before they are written to disk.
    private var accelerationsCache = [Acceleration]()

    /// An in memory storage for geo locations, before they are written to disk.
    private var locationsCache = [GeoLocation]()

    /// The background queue used to capture data.
    private let capturingQueue = DispatchQueue.global(qos: .userInitiated)

    /// Synchronizes read and write operations on the `locationsCache` and the `accelerationsCache`.
    private let cacheSynchronizationQueue = DispatchQueue(label: "cacheSynchronization", attributes: .concurrent)

    private let lifecycleQueue = DispatchQueue(label: "lifecylce")

    /// The interval between data write opertions, during data capturing.
    private let savingInterval: TimeInterval

    /// A timer called in regular intervals to save the captured data to the underlying database.
    private var backgroundSynchronizationTimer: DispatchSourceTimer!

    /// An optional API that is responsible for synchronizing data with a Cyface server.
    public var synchronizer: Synchronizer?

    // MARK: - Initializers
    /**
     Creates a new completely initialized `DataCapturingService` transmitting data
     via the provided server connection and accessing data a certain amount of times per second.
     - Parameters:
     
     - sensorManager: An instance of `CMMotionManager`.
     There should be only one instance of this type in your application.
     Since it seems to be impossible to create that instance inside a framework at the moment,
     you have to provide it via this parameter.
     - updateInterval: The accelerometer update interval in Hertz. By default this is set to the supported maximum of 100 Hz.
     - savingInterval: The interval in seconds to wait between saving data to the database. A higher number increses speed but requires more memory and leads to a bigger risk of data loss. A lower number incurs higher demands on the systems processing speed.
     - persistenceLayer: An API to store, retrieve and update captured data to the local system until the App can transmit it to a server.
     - dataSynchronizationIsActive: A flag telling the system, whether it should synchronize data or not. If this is `true` data will be synchronized; if it is `false`, no data will be synchronized.
     - eventHandler: An optional handler used by the capturing process to inform about `DataCapturingEvent`s.
     */
    public init(
        sensorManager manager: CMMotionManager,
        updateInterval interval: Double = 100,
        savingInterval time: TimeInterval = 30,
        persistenceLayer persistence: PersistenceLayer,
        synchronizer: Synchronizer?,
        eventHandler: @escaping ((DataCapturingEvent, Status) -> Void)) {

        self.isRunning = false
        self.isPaused = false
        self.persistenceLayer = persistence
        self.motionManager = manager
        motionManager.accelerometerUpdateInterval = 1.0 / interval
        self.handler = eventHandler
        self.synchronizer = synchronizer
        self.savingInterval = time

        super.init()
    }

    // MARK: - Public API Methods

    /**
     Starts the capturing process.

     This startup procedure is asynchronous.
     The event handler provided to the initializer receives a `DataCapturingEvent.serviceStarted`, after the startup has finished.
     If an error happened during this process, it is provided as part of this handlers `Status` argument.
     
     - Parameters:
     - context: The `MeasurementContext` to use for the newly created measurement.
     
     - Throws:
     - `DataCapturingError.isPaused` if the service was paused and thus starting it makes no sense. If you need to continue call `resume(((DataCapturingEvent) -> Void))`.
     */
    public func start(inContext context: MeasurementContext) throws {
        try lifecycleQueue.sync {
            guard !isPaused else {
                throw DataCapturingError.isPaused
            }

            let timestamp = currentTimeInMillisSince1970()
            persistenceLayer.context = persistenceLayer.makeContext()
            let measurement = try persistenceLayer.createMeasurement(at: timestamp, withContext: context)
            let measurementEntity = MeasurementEntity(identifier: measurement.identifier, context: context)
            self.currentMeasurement = measurementEntity
            try startCapturing(savingEvery: savingInterval)
            handler(.serviceStarted(measurement: measurementEntity.identifier), .success)
        }
    }

    /**
     Stops the currently running data capturing process or does nothing if the process is not
     running.

     - Throws:
     - `DataCapturingError.isPaused` if the service was paused and thus stopping it makes no sense.
     */
    public func stop() throws {
        try lifecycleQueue.sync {
            guard !isPaused else {
                throw DataCapturingError.isPaused
            }

            stopCapturing()
            currentMeasurement = nil
            if let synchronizer = synchronizer {
                synchronizer.activate()
            }
        }
    }

    /**
     Pauses the current data capturing measurement for the moment. No data is captured until `resume()` has been called, but upon the call to `resume()` the last measurement will be continued instead of beginning a new now. After using `pause()` you must call resume before you can call any other lifecycle method like `stop()`, for example.

     - Throws:
     - `DataCaturingError.notRunning` if the service was not running and thus pausing it makes no sense.
     - `DataCapturingError.isPaused` if the service was already paused and pausing it again makes no sense.
     */
    public func pause() throws {
        try lifecycleQueue.sync {
            guard isRunning else {
                throw DataCapturingError.notRunning
            }

            guard !isPaused else {
                throw DataCapturingError.isPaused
            }

            stopCapturing()
            isPaused = true
        }
    }

    /**
     Resumes the current data capturing with the data capturing measurement that was running when `pause()` was called. A call to this method is only valid after a call to `pause()`. It is going to fail if used after `start()` or `stop()`.

     - Throws:
     - `DataCapturingError.notPaused`: If the service was not paused and thus resuming it makes no sense.
     - `DataCapturingError.isRunning`: If the service was running and thus resuming it makes no sense.
     - `DataCapturingError.noCurrentMeasurement`: If no current measurement is available while resuming data capturing.
     */
    public func resume() throws {
        try lifecycleQueue.sync {
            guard isPaused else {
                throw DataCapturingError.notPaused
            }

            guard !isRunning else {
                throw DataCapturingError.isRunning
            }

            try startCapturing(savingEvery: savingInterval)
            isPaused = false
        }
    }

    // MARK: - Internal Support Methods

    /**
     Internal method for starting the capturing process. This can optionally take in a handler for events occuring during data capturing.

     - Parameter savingEvery: The interval in seconds to wait between saving data to the database. A higher number increses speed but requires more memory and leads to a bigger risk of data loss. A lower number incurs higher demands on the systems processing speed.
     */
    func startCapturing(savingEvery time: TimeInterval) throws {
        // Preconditions
        guard !isRunning else {
            return os_log("DataCapturingService.startCapturing(): Trying to start DataCapturingService which is already running!", log: LOG, type: .info)
        }

        guard let currentMeasurement = currentMeasurement else {
            throw DataCapturingError.noCurrentMeasurement
        }

        persistenceLayer.context = persistenceLayer.makeContext()
        let measurement = try persistenceLayer.load(measurementIdentifiedBy: currentMeasurement.identifier)
        try persistenceLayer.appendNewTrack(to: measurement)
        self.locationManager.delegate = self

        let queue = OperationQueue()
        queue.qualityOfService = QualityOfService.userInitiated
        queue.underlyingQueue = self.capturingQueue
        if self.motionManager.isAccelerometerAvailable {
            self.motionManager.startAccelerometerUpdates(to: queue) { data, _ in
                guard let myData = data else {
                    // Should only happen if the device accelerometer is broken or something similar. If this leads to problems we can substitute by a soft error handling such as a warning or something similar. However in such a case we might think everything works fine, while it really does not.
                    fatalError("DataCapturingService.start(): No Accelerometer data available!")
                }

                let accValues = myData.acceleration
                let acc = Acceleration(timestamp: self.currentTimeInMillisSince1970(),
                                       x: accValues.x,
                                       y: accValues.y,
                                       z: accValues.z)
                // Synchronize this write operation.
                self.cacheSynchronizationQueue.async(flags: .barrier) {
                    self.accelerationsCache.append(acc)
                }
            }
        }

        self.backgroundSynchronizationTimer = DispatchSource.makeTimerSource(queue: self.cacheSynchronizationQueue)
        self.backgroundSynchronizationTimer.setEventHandler(handler: self.saveCapturedData)
        self.backgroundSynchronizationTimer.schedule(deadline: .now(), repeating: time)
        self.backgroundSynchronizationTimer.resume()

        DispatchQueue.main.async {
            self.locationManager.startUpdatingLocation()
        }

        self.isRunning = true
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
        backgroundSynchronizationTimer.cancel()
        saveCapturedData()
        isRunning = false

    }

    /**
     Method called by the `backgroundSynchronizationTimer` on each invocation.

     This method saves all data from `accelerationsCache` and from `locationsCache` to the underlying data storage (database and file system) and cleans both caches.
     */
    func saveCapturedData() {
        guard let measurement = currentMeasurement else {
            // Using a fatal error here since we can not provide a callback or throw an error. If this leads to App crashes a soft catch of this error is possible, by just printing a warning or something similar.
            fatalError("No current measurement to save the location to! Data capturing impossible.")
        }

        cacheSynchronizationQueue.async(flags: .barrier) {
            do {
                let localAccelerationsCache = self.accelerationsCache
                let localLocationsCache = self.locationsCache

                self.persistenceLayer.context = self.persistenceLayer.makeContext()
                let measurement = try self.persistenceLayer.load(measurementIdentifiedBy: measurement.identifier)

                try self.persistenceLayer.save(locations: localLocationsCache, in: measurement)
                try self.persistenceLayer.save(accelerations: localAccelerationsCache, in: measurement)

                self.accelerationsCache = [Acceleration]()
                self.locationsCache = [GeoLocation]()
            } catch let error {
                return os_log("Unable to save captured data. Error %@", log: self.LOG, type: .error, error.localizedDescription)
            }
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

        for location in locations {
            // Smooth the way by removing outlier coordinates.
            let howRecent = location.timestamp.timeIntervalSinceNow
            guard location.horizontalAccuracy < 20 && abs(howRecent) < 10 else { continue }

            let geoLocation = GeoLocation(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                accuracy: location.horizontalAccuracy,
                speed: location.speed,
                timestamp: convertToUtcTimestamp(date: location.timestamp))

            cacheSynchronizationQueue.async(flags: .barrier) {
                self.locationsCache.append(geoLocation)
            }

            DispatchQueue.main.async {
                self.handler(.geoLocationAcquired(position: geoLocation), .success)
            }
        }
    }

    /**
     The listener method informed about error during location tracking. Just prints those errors to the log.

     - Parameters:
     - manager: The location manager reporting the error.
     - didFailWithError: The reported error.
     */
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        os_log("Location service failed with error: %@!", log: LOG, type: .error, error.localizedDescription)
    }
}
