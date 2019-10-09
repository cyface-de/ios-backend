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
 An object of this class handles the lifecycle of starting and stopping data capturing.
 
 - Author: Klemens Muthmann
 - Version: 9.4.0
 - Since: 1.0.0
 */
public class DataCapturingService: NSObject {

    // MARK: - Properties
    /// Data used to identify log messages created by this component.
    private let log = OSLog(subsystem: "de.cyface", category: "DataCapturingService")

    /// `true` if data capturing is running; `false` otherwise.
    public var isRunning = false

    /// `true` if data capturing was running but is currently paused; `false` otherwise.
    public var isPaused = false

    // TODO: This should probably be a MeasurementMO which is checked for fault on each call. In addition it might be a good idea to merge the DataCapturingService into the MeasurementMO class, since it only represents the behaviour of the measurement
    /// The currently recorded `Measurement` or `nil` if there is no active recording.
    public var currentMeasurement: Int64?

    /// Locations are captured approximately once per second on most devices. If you would like to get fewer updates this parameter controls, how many events are skipped before one is reported to your handler. The default value is 1, which reports every event. To receive fewer events you could for example set it to 5 to only receive every fifth event.
    public var locationUpdateSkipRate: UInt = 1 {
        willSet(newValue) {
            if newValue==0 {
                fatalError("Invalid value 0 for locationUpdateSkipRate!")
            }
        }
    }

    /**
     Provides access to the devices geo location capturing hardware (such as GPS, GLONASS, GALILEO, etc.)
     and handles geo location updates in the background.
     */
    lazy var coreLocationManager: LocationManager = {
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
     The *CoreData* stack used to store, retrieve and update captured data to the local system until the App can transmit it to a server.
     */
    let coreDataStack: CoreDataManager

    /// An in memory storage for accelerations, before they are written to disk.
    var accelerationsCache = [Acceleration]()

    /// An in memory storage for geo locations, before they are written to disk.
    var locationsCache = [GeoLocation]()

    /// The background queue used to capture data.
    let capturingQueue = DispatchQueue.global(qos: .userInitiated)

    /// An instance of `CMMotionManager`. There should be only one instance of this type in your application.
    private let motionManager: CMMotionManager

    /// A listener that is notified of important events during data capturing.
    private var handler: ((DataCapturingEvent, Status) -> Void)

    /**
     A queue used to synchronize calls to the lifecycle methods `start`, `pause`, `resume` and `stop`.
     Using such a queue prevents successiv calls to these methods to interrupt each other.
     */
    private let lifecycleQueue = DispatchQueue(label: "lifecylce")

    /// The interval between data write opertions, during data capturing.
    private let savingInterval: TimeInterval

    /// A timer called in regular intervals to save the captured data to the underlying database.
    private var backgroundSynchronizationTimer: DispatchSourceTimer!

    /// The number of the current event. This is used to filter events based on `locationUpdateRate`.
    private var geoLocationEventNumber = 0

    /// Marks captured positions as valid (clean) or invalid (not clean). This removes outliers and jitter while standing.
    private let trackCleaner = DefaultTrackCleaner()

    /// This is the maximum time between two location updates allowed before the service assumes that it does not have a valid location fix anymore.
    private static let maxAllowedTimeBetweenLocationUpdatesInMillis = Int64(2_000)

    /// The timestamp in UNIX timestamp format in milliseconds since the 1st of january 1970 of the last geo location update event.
    private var prevLocationUpdateTimeInMillis: Int64?

    /// The internal storage variable for the fix state.
    private var _hasFix = false

    /// The current state of the geo location fix with a geo location network (GPS, GLONASS, Galileo, etc.)
    private var hasFix: Bool {
        set {
            guard newValue != _hasFix else {
                return
            }

            if newValue {
                handler(DataCapturingEvent.geoLocationFixAcquired, Status.success)
            } else {
                handler(DataCapturingEvent.geoLocationFixLost, Status.success)
            }
            _hasFix = newValue
        }
        get {
            return _hasFix
        }
    }

    // MARK: - Initializers

    /**
     Creates a new completely initialized `DataCapturingService` accessing data a certain amount of times per second.

     - Parameters:
        - sensorManager: An instance of `CMMotionManager`.
     There should be only one instance of this type in your application.
     Since it seems to be impossible to create that instance inside a framework at the moment, you have to provide it via this parameter.
        - updateInterval: The accelerometer update interval in Hertz. By default this is set to the supported maximum of 100 Hz.
        - savingInterval: The interval in seconds to wait between saving data to the database. A higher number increses speed but requires more memory and leads to a bigger risk of data loss. A lower number incurs higher demands on the systems processing speed.
        - dataManager: The `CoreData` stack used to store, retrieve and update captured data to the local system until the App can transmit it to a server.
        - eventHandler: An optional handler used by the capturing process to inform about `DataCapturingEvent`s.
     */
    public init(
        sensorManager manager: CMMotionManager,
        updateInterval interval: Double = 100,
        savingInterval time: TimeInterval = 30,
        dataManager: CoreDataManager,
        eventHandler: @escaping ((DataCapturingEvent, Status) -> Void)) {

        coreDataStack = dataManager
        self.motionManager = manager
        motionManager.accelerometerUpdateInterval = 1.0 / interval
        self.handler = eventHandler
        self.savingInterval = time

        let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
        persistenceLayer.context = persistenceLayer.makeContext()

        do {
            for measurement in try persistenceLayer.loadMeasurements() {
                if !measurement.synchronizable && !measurement.synchronized {
                    currentMeasurement = measurement.identifier
                    isPaused = true
                }
            }
        } catch {
            fatalError("Unable to load measurements from database!")
        }

        super.init()
    }

    // MARK: - Public API Methods

    /**
     Starts the capturing process.

     This startup procedure is asynchronous.
     The event handler provided to the initializer receives a `DataCapturingEvent.serviceStarted`, after the startup has finished.
     If an error happened during this process, it is provided as part of this handlers `Status` argument.
     
     - Parameters:
        - modality: The mode of transportation to use for the newly created measurement. This should be something like "car" or "bicycle".
     
     - Throws:
        - `DataCapturingError.isPaused` if the service was paused and thus starting it makes no sense. If you need to continue call `resume(((DataCapturingEvent) -> Void))`.
     */
    public func start(inMode modality: String) throws {
        try lifecycleQueue.sync {
            if isPaused {
                os_log("Starting data capturing on paused service. Finishing paused measurements and starting fresh. This is probably the result of a lifecycle error. ", log: log, type: .default)
                if let currentMeasurement = currentMeasurement {
                    try finish(measurement: currentMeasurement)
                }
            }

            let timestamp = DataCapturingService.currentTimeInMillisSince1970()
            let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
            persistenceLayer.context = persistenceLayer.makeContext()

            let measurement = try persistenceLayer.createMeasurement(at: timestamp, inMode: modality)

            self.currentMeasurement = measurement.identifier
            persistenceLayer.context?.saveRecursively()

            try startCapturing(savingEvery: savingInterval, for: .lifecycleStart)

            handler(.serviceStarted(measurement: measurement.identifier), .success)
        }
    }

    /**
     Stops the currently running or paused data capturing process or does nothing if the process is not
     running.

     - Throws:
        - `PersistenceError` If the currently captured measurement was not found in the database.
        - Some unspecified errors from within *CoreData*.
     */
    public func stop() throws {
        try lifecycleQueue.sync {
            guard let currentMeasurement = currentMeasurement else {
                os_log("Trying to stop a stopped service! Ignoring call to stop!", log: log, type: .default)
                return
            }

            guard isPaused || isRunning else {
                fatalError("Trying to stop a not initialized service (not running and not paused)!")
            }

            // Inform about stopped event
            backgroundSynchronizationTimer?.setCancelHandler {
                self.handler(.serviceStopped(measurement: currentMeasurement), .success)
            }
            stopCapturing()
            try finish(measurement: currentMeasurement)
            self.currentMeasurement = nil
            isPaused = false
        }
    }

    /**
     Pauses the current data capturing measurement for the moment. No data is captured until `resume()` has been called, but upon the call to `resume()` the last measurement will be continued instead of beginning a new now.

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

            guard let currentMeasurement = currentMeasurement else {
                fatalError("No current measurement available in paused state!")
            }

            stopCapturing()
            isPaused = true
            let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
            persistenceLayer.context = persistenceLayer.makeContext()
            let measurement = try persistenceLayer.load(measurementIdentifiedBy: currentMeasurement)
            measurement.addToEvents(persistenceLayer.createEvent(of: .lifecyclePause))
            persistenceLayer.context?.saveRecursively()
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

            guard let currentMeasurement = currentMeasurement else {
                fatalError("No measurement to resume")
            }

            try startCapturing(savingEvery: savingInterval, for: .lifecycleResume)
            isPaused = false

            handler(.serviceResumed(measurement: currentMeasurement), .success)
        }
    }

    /**
     Changes the current mode of transportation of the measurement. This can happen if the user switches for example from a bicycle to a car.
     If the new modality is the same as the old one, the method returns without doing anything.

     - Parameter to: The modality context to switch to.
     */
    public func changeModality(to modality: String) {
        lifecycleQueue.sync {
            guard let currentMeasurementIdentifier = currentMeasurement else {
                return
            }

            let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
            persistenceLayer.context = persistenceLayer.makeContext()

            do {
                let currentMeasurementMO = try persistenceLayer.load(measurementIdentifiedBy: currentMeasurementIdentifier)

                let existingModalityChangeEvents = try persistenceLayer.loadEvents(typed: .modalityTypeChange, forMeasurement: currentMeasurementMO)
                guard let lastModalityChangeEvent = existingModalityChangeEvents.last else {
                    fatalError("No valid modality change event!")
                }

                if lastModalityChangeEvent.value == modality {
                    return
                }

                let event = persistenceLayer.createEvent(of: .modalityTypeChange, withValue: modality)
                currentMeasurementMO.addToEvents(event)
                persistenceLayer.context?.saveRecursively()
            } catch {
                fatalError("Unable to load measurement identified by \(currentMeasurementIdentifier)!")
            }
        }
    }

    // MARK: - Internal Support Methods

    /**
     Internal method for starting the capturing process. This can optionally take in a handler for events occuring during data capturing.

     - Parameter savingEvery: The interval in seconds to wait between saving data to the database. A higher number increses speed but requires more memory and leads to a bigger risk of data loss. A lower number incurs higher demands on the systems processing speed.
     - Parameter event: The event causing this start call.
     - Throws:
        - `PersistenceError` If there is no current measurement.
        - Some unspecified errors from within CoreData.
     */
    func startCapturing(savingEvery time: TimeInterval, for event: EventType) throws {
        // Preconditions
        guard !isRunning else {
            return os_log("DataCapturingService.startCapturing(): Trying to start DataCapturingService which is already running!", log: log, type: .info)
        }

        guard let currentMeasurement = currentMeasurement else {
            throw DataCapturingError.noCurrentMeasurement
        }

        let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
        persistenceLayer.context = persistenceLayer.makeContext()
        let measurement = try persistenceLayer.load(measurementIdentifiedBy: currentMeasurement)
        persistenceLayer.appendNewTrack(to: measurement)
        measurement.addToEvents(persistenceLayer.createEvent(of: event))
        self.coreLocationManager.locationDelegate = self

        let queue = OperationQueue()
        queue.qualityOfService = QualityOfService.userInitiated
        queue.underlyingQueue = self.capturingQueue
        if self.motionManager.isAccelerometerAvailable {
            self.motionManager.startAccelerometerUpdates(to: queue, withHandler: handleAccelerometerUpdate)
        }

        self.backgroundSynchronizationTimer = DispatchSource.makeTimerSource(queue: self.lifecycleQueue)
        self.backgroundSynchronizationTimer.setEventHandler { [weak self] in
            guard let self = self else {
                return
            }

            self.saveCapturedData()

            guard let prevLocationUpdateTimeInMillis = self.prevLocationUpdateTimeInMillis else {
                self.hasFix = false
                return
            }

            if DataCapturingService.currentTimeInMillisSince1970() - prevLocationUpdateTimeInMillis < DataCapturingService.maxAllowedTimeBetweenLocationUpdatesInMillis {
                self.hasFix = true
            } else {
                self.hasFix = false
            }
        }

        self.backgroundSynchronizationTimer.schedule(deadline: .now(), repeating: time)
        self.backgroundSynchronizationTimer.resume()

        DispatchQueue.main.async {
            self.coreLocationManager.startUpdatingLocation()
        }

        self.isRunning = true
    }

    /**
     An internal helper method for stopping the capturing process.
     */
    func stopCapturing() {
        motionManager.stopAccelerometerUpdates()
        DispatchQueue.main.async {
            self.coreLocationManager.stopUpdatingLocation()
        }
        coreLocationManager.locationDelegate = nil
        backgroundSynchronizationTimer.cancel()
            if !locationsCache.isEmpty || !accelerationsCache.isEmpty {
                saveCapturedData()
            }
        isRunning = false

    }

    /**
     Method called by the `backgroundSynchronizationTimer` on each invocation.

     This method saves all data from `accelerationsCache` and from `locationsCache` to the underlying data storage (database and file system) and cleans both caches.
     */
    func saveCapturedData() {
        do {
            guard let currentMeasurement = self.currentMeasurement else {
                os_log("No current measurement to save the location to! Data capturing impossible.", log: log, type: .error)
                return
            }

            let localAccelerationsCache = self.accelerationsCache
            let localLocationsCache = self.locationsCache

            let persistenceLayer = PersistenceLayer(onManager: self.coreDataStack)
            persistenceLayer.context = persistenceLayer.makeContext()
            let measurement = try persistenceLayer.load(measurementIdentifiedBy: currentMeasurement)

            try persistenceLayer.save(locations: localLocationsCache, in: measurement)
            try persistenceLayer.save(accelerations: localAccelerationsCache, in: measurement)

            self.accelerationsCache = [Acceleration]()
            self.locationsCache = [GeoLocation]()
        } catch let error {
            return os_log("Unable to save captured data. Error %@", log: self.log, type: .error, error.localizedDescription)
        }
    }

    /**
     Finishes the provided measurement if still open and marks this event in the list of events.
     This method does not check if the measurement is already finished, so be careful to only call it on non finished measurements.

     - Parameter measurement: The device wide unique identifier of the measurement to finish.
     */
    private func finish(measurement: Int64) throws {
        let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
        persistenceLayer.context = persistenceLayer.makeContext()
        let currentMeasurementEntity = try persistenceLayer.load(measurementIdentifiedBy: measurement)
        currentMeasurementEntity.synchronizable = true
        currentMeasurementEntity.addToEvents(persistenceLayer.createEvent(of: .lifecycleStop))
        persistenceLayer.context?.saveRecursively()
    }

    private func handleAccelerometerUpdate(_ data: CMAccelerometerData?, _ error: Error?) {
        if let error = error as? CMError {
            os_log("Accelerometer error: %@", log: log, type: .error, error.rawValue)
        }

        guard let data = data else {
            // Should only happen if the device accelerometer is broken or something similar. If this leads to problems we can substitute by a soft error handling such as a warning or something similar. However in such a case we might think everything works fine, while it really does not.
            fatalError("DataCapturingService.start(): No Accelerometer data available!")
        }

        let accValues = data.acceleration
        let acc = Acceleration(timestamp: DataCapturingService.currentTimeInMillisSince1970(),
                               x: accValues.x,
                               y: accValues.y,
                               z: accValues.z)
        // Synchronize this write operation.
        self.lifecycleQueue.async(flags: .barrier) {
            self.accelerationsCache.append(acc)
        }
    }

    /// Provides the current time in milliseconds since january 1st 1970 (UTC).
    public static func currentTimeInMillisSince1970() -> Int64 {
        return convertToUtcTimestamp(date: Date())
    }

    /// Converts a `Data` object to a UTC milliseconds timestamp since january 1st 1970.
    private static func convertToUtcTimestamp(date value: Date) -> Int64 {
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

     - Remark:
        This function is one of the most critical parts of the `DataCapturingService`. It is called once per second and should not do any unncessary work.
     - Parameters:
        - manager: The location manager used.
        - didUpdateLocation: An array of the updated locations.
     */
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        for location in locations {
            let timestamp = DataCapturingService.convertToUtcTimestamp(date: location.timestamp)
            prevLocationUpdateTimeInMillis = timestamp

            let isValid = trackCleaner.isValid(location: location)
            let geoLocation = GeoLocation(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                accuracy: location.horizontalAccuracy,
                speed: location.speed,
                timestamp: timestamp,
                isValid: isValid)

            lifecycleQueue.async(flags: .barrier) {
                self.locationsCache.append(geoLocation)
            }

            geoLocationEventNumber += 1
            if geoLocationEventNumber == 1 {
                // TODO: Actually the calling app should care for whether this happens on the main thread or not. Nevertheless it must be synchronized. It could be added to the lifecycleQueue to achieve this. Maybe with version 5.
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else {
                        return
                    }

                    self.handler(.geoLocationAcquired(position: geoLocation), .success)
                }
            }
            if geoLocationEventNumber == locationUpdateSkipRate {
                geoLocationEventNumber = 0
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
        os_log("Location service failed with error: %@!", log: log, type: .error, error.localizedDescription)
        hasFix = false
    }
}
