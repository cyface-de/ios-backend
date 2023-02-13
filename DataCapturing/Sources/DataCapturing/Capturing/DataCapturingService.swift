/*
 * Copyright 2017 - 2022 Cyface GmbH
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
 - Version: 10.2.0
 - Since: 1.0.0
 */
public class DataCapturingService: NSObject {

    // MARK: - Properties
    /// Data used to identify log messages created by this component.
    private static let log = OSLog(subsystem: "de.cyface", category: "DataCapturingService")

    /// `true` if data capturing is running; `false` otherwise.
    public var isRunning = false

    /// `true` if data capturing was running but is currently paused; `false` otherwise.
    public var isPaused = false

    // TODO: This should probably be a Measurement which is checked for fault on each call. In addition it might be a good idea to merge the DataCapturingService into the MeasurementMO class, since it only represents the behaviour of the measurement
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
    public let coreDataStack: CoreDataManager

    /// An in memory storage for geo locations, before they are written to disk.
    var locationsCache = [LocationCacheEntry]()

    /// The background queue used to capture data.
    let capturingQueue = DispatchQueue.global(qos: .userInitiated)

    /// An object that handles capturing of values from the smartphones sensors excluding geo locations (GPS, GLONASS, GALILEO, etc.).
    let sensorCapturer: SensorCapturer

    /// A list of listeners that are notified of important events during data capturing.
    public var handler = [((DataCapturingEvent, Status) -> Void)]()

    /**
     A queue used to synchronize calls to the lifecycle methods `start`, `pause`, `resume` and `stop`.
     Using such a queue prevents successiv calls to these methods to interrupt each other.
     */
    private let lifecycleQueue = DispatchQueue(label: "lifecylce")

    /// The interval between data write opertions, during data capturing.
    private let savingInterval: TimeInterval

    /// A timer called in regular intervals to save the captured data to the underlying database.
    private var backgroundSynchronizationTimer: DispatchSourceTimer?

    /// The number of the current event. This is used to filter events based on `locationUpdateRate`.
    private var geoLocationEventNumber = 0

    /// Marks captured positions as valid (clean) or invalid (not clean). This removes outliers and jitter while standing.
    private let trackCleaner = DefaultTrackCleaner()

    /// This is the maximum time between two location updates allowed before the service assumes that it does not have a valid location fix anymore.
    private static let maxAllowedTimeBetweenLocationUpdatesInMillis = TimeInterval(2.0)

    /// The timestamp of the last geo location update event.
    private var prevLocationUpdateTime: Date?

    /// The internal storage variable for the fix state.
    private var _hasFix = false

    /// The current state of the geo location fix with a geo location network (GPS, GLONASS, Galileo, etc.)
    private var hasFix: Bool {
        get {
            return _hasFix
        }
        set {
            guard newValue != _hasFix else {
                return
            }

            if newValue {
                handle(event: DataCapturingEvent.geoLocationFixAcquired, status: Status.success)
            } else {
                handle(event: DataCapturingEvent.geoLocationFixLost, status: Status.success)
            }
            _hasFix = newValue
        }
    }

    // MARK: - Initializers

    /**
     Creates a new completely initialized `DataCapturingService` accessing data a certain amount of times per second.

     - Parameters:
        - sensorManager: An instance of `CMMotionManager`.
     There should be only one instance of this type in your application.
     Since it seems to be impossible to create that instance inside a framework at the moment, you have to provide it via this parameter.
        - accelerometerInterval: The accelerometer update interval in Hertz. By default this is set to the supported maximum of 100 Hz.
        - gyroInterval: The gyroscope update interval in Hertz. By default this is set to the supported maximum of 100 Hz.
        - directionsInterval: The magnetometer update interval in Hertz. By default this is set to the supported maximum of 100 Hz.
        - savingInterval: The interval in seconds to wait between saving data to the database. A higher number increses speed but requires more memory and leads to a bigger risk of data loss. A lower number incurs higher demands on the systems processing speed.
        - dataManager: The `CoreData` stack used to store, retrieve and update captured data to the local system until the App can transmit it to a server.
        - eventHandler: An optional handler used by the capturing process to inform about `DataCapturingEvent`s.
     */
    public init(
        sensorManager manager: CMMotionManager,
        accelerometerInterval: Double = 100,
        gyroInterval: Double = 100,
        directionsInterval: Double = 100,
        savingInterval time: TimeInterval = 30,
        dataManager: CoreDataManager) {

        coreDataStack = dataManager
        manager.accelerometerUpdateInterval = 1.0 / accelerometerInterval
        manager.gyroUpdateInterval = 1.0 / gyroInterval
        manager.magnetometerUpdateInterval = 1.0 / directionsInterval
        self.sensorCapturer = SensorCapturer(lifecycleQueue: lifecycleQueue, capturingQueue: capturingQueue, motionManager: manager)
        self.savingInterval = time

        super.init()
    }

    // MARK: - Public API Methods
    /**
     Puts the `DataCapturingService` in the correct state according to the current database values.

     - Attention: This method must be called before calling any other method from the `DataCapturingService`
     */
    public func setup() {
        let persistenceLayer = PersistenceLayer(onManager: coreDataStack)

        do {
            for var measurement in try persistenceLayer.loadMeasurements() {
                if !measurement.synchronizable && !measurement.synchronized {
                    currentMeasurement = measurement.identifier
                    let pauseEvent = try persistenceLayer.createEvent(of: .lifecyclePause, parent: &measurement)
                    isPaused = true
                    self.handle(event: .servicePaused(measurement: currentMeasurement, event: pauseEvent), status: .success)
                }
            }
        } catch {
            fatalError("Unable to load measurements from database! Reason: \(error)")
        }
    }

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
                os_log(
                    """
Starting data capturing on paused service. Finishing paused measurements and starting fresh. This is probably the result of a lifecycle error.
""",
                    log: DataCapturingService.log,
                    type: .error)
                if let currentMeasurement = currentMeasurement {
                    _ = try finish(measurement: currentMeasurement)
                }
                self.isPaused = false
            }

            let timestamp = DataCapturingService.currentTimeInMillisSince1970()
            let persistenceLayer = PersistenceLayer(onManager: coreDataStack)

            let measurement = try persistenceLayer.createMeasurement(at: timestamp, inMode: modality)

            self.currentMeasurement = measurement.identifier

            if let event = try startCapturing(savingEvery: savingInterval, for: .lifecycleStart) {
                handle(event: .serviceStarted(measurement: measurement.identifier, event: event), status: .success)
            }
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
                os_log("Trying to stop a stopped service! Ignoring call to stop!", log: DataCapturingService.log, type: .error)
                return
            }

            guard isPaused || isRunning else {
                fatalError("Trying to stop a not initialized service (not running and not paused)!")
            }

            // Inform about stopped event
            stopCapturing()
            let event = try finish(measurement: currentMeasurement)
            self.currentMeasurement = nil
            isPaused = false

            self.handle(event: .serviceStopped(measurement: currentMeasurement, event: event), status: .success)
            os_log("Stopped data capturing service for measurement %{PUBLIC}d.",
                   log: DataCapturingService.log,
                   type: .info,
                   currentMeasurement)
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
            var measurement = try persistenceLayer.load(measurementIdentifiedBy: currentMeasurement)
            let event = try persistenceLayer.createEvent(of: .lifecyclePause, parent: &measurement)

            handle(event: .servicePaused(measurement: currentMeasurement, event: event), status: .success)
            os_log("Paused data capturing service for measurement ${PUBLIC}d.\nDistance Covered: %{PUBLIC}f",
                   log: DataCapturingService.log,
                   type: .info,
                   measurement.identifier,
                   measurement.trackLength)
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

            if let startEvent = try startCapturing(savingEvery: savingInterval, for: .lifecycleResume) {
                isPaused = false

                handle(event: .serviceResumed(measurement: currentMeasurement, event: startEvent), status: .success)
                os_log("Resumed data capturing service for measurement %{PUBLIC}d.",
                       log: DataCapturingService.log,
                       type: .info,
                       currentMeasurement)
            }
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

            do {
                var currentMeasurement = try persistenceLayer.load(measurementIdentifiedBy: currentMeasurementIdentifier)

                let existingModalityChangeEvents = try persistenceLayer.loadEvents(typed: .modalityTypeChange, forMeasurement: currentMeasurement)
                guard let lastModalityChangeEvent = existingModalityChangeEvents.last else {
                    fatalError("No valid modality change event!")
                }

                if lastModalityChangeEvent.value == modality {
                    return
                }

                _ = try persistenceLayer.createEvent(of: .modalityTypeChange, withValue: modality, parent: &currentMeasurement)
            } catch {
                fatalError("Unable to load measurement identified by \(currentMeasurementIdentifier)!")
            }
        }
    }

    // MARK: - Internal Support Methods

    /**
     Internal method for starting the capturing process. This can optionally take in a handler for events occuring during data capturing.

     - Parameter savingEvery: The interval in seconds to wait between saving data to the database. A higher number increses speed but requires more memory and leads to a bigger risk of data loss. A lower number incurs higher demands on the systems processing speed.
     - Parameter eventType: The type of event causing this start call.
     - Returns: The event with information about starting the data capturing service
     - Throws:
        - `PersistenceError` If there is no current measurement.
        - Some unspecified errors from within CoreData.
     */
    func startCapturing(savingEvery time: TimeInterval, for eventType: EventType) throws -> Event? {
        // Preconditions
        guard !isRunning else {
            os_log("DataCapturingService.startCapturing(): Trying to start DataCapturingService which is already running!",
                   log: DataCapturingService.log,
                   type: .info)
            return nil
        }

        guard let currentMeasurement = currentMeasurement else {
            throw DataCapturingError.noCurrentMeasurement
        }

        let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
        var measurement = try persistenceLayer.load(measurementIdentifiedBy: currentMeasurement)
        try persistenceLayer.appendNewTrack(to: &measurement)
        let event = try persistenceLayer.createEvent(of: eventType, parent: &measurement)
        self.coreLocationManager.locationDelegate = self

        sensorCapturer.start()

        let backgroundSynchronizationTimer = DispatchSource.makeTimerSource(queue: self.lifecycleQueue)
        backgroundSynchronizationTimer.setEventHandler { [weak self] in
            guard let self = self else {
                return
            }

            self.saveCapturedData()

            guard let prevLocationUpdateTimeInMillis = self.prevLocationUpdateTime else {
                self.hasFix = false
                return
            }

            if prevLocationUpdateTimeInMillis.timeIntervalSinceNow < DataCapturingService.maxAllowedTimeBetweenLocationUpdatesInMillis {
                self.hasFix = true
            } else {
                self.hasFix = false
            }
        }

        backgroundSynchronizationTimer.schedule(deadline: .now(), repeating: time)
        backgroundSynchronizationTimer.activate()
        self.backgroundSynchronizationTimer = backgroundSynchronizationTimer

        DispatchQueue.main.async {
            self.coreLocationManager.startUpdatingLocation()
        }

        self.isRunning = true
        return event
    }

    /**
     An internal helper method for stopping the capturing process.
     */
    func stopCapturing() {
        sensorCapturer.stop()
        DispatchQueue.main.async {
            self.coreLocationManager.stopUpdatingLocation()
        }
        coreLocationManager.locationDelegate = nil
        backgroundSynchronizationTimer?.cancel()
        if !locationsCache.isEmpty || !sensorCapturer.isEmpty {
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
                os_log("No current measurement to save the location to! Data capturing impossible.", log: DataCapturingService.log, type: .error)
                return
            }

            let localAccelerationsCache = sensorCapturer.accelerations
            let localRotationsCache = sensorCapturer.rotations
            let localDirectionsCache = sensorCapturer.directions
            let localLocationsCache = self.locationsCache

            let persistenceLayer = PersistenceLayer(onManager: self.coreDataStack)
            var measurement = try persistenceLayer.load(measurementIdentifiedBy: currentMeasurement)

            try persistenceLayer.save(locations: localLocationsCache, in: &measurement)

            try persistenceLayer.save(
                accelerations: localAccelerationsCache,
                rotations: localRotationsCache,
                directions: localDirectionsCache,
                in: &measurement)

            sensorCapturer.accelerations.removeAll()
            sensorCapturer.rotations.removeAll()
            sensorCapturer.directions.removeAll()

            self.locationsCache = [LocationCacheEntry]()
        } catch let error {
            return os_log("Unable to save captured data. Error %{public}@", log: DataCapturingService.log, type: .error, error.localizedDescription)
        }
    }

    /**
     Finishes the provided measurement if still open and marks this event in the list of events.
     This method does not check if the measurement is already finished, so be careful to only call it on non finished measurements.

     - Parameter measurement: The device wide unique identifier of the measurement to finish
     - Returns: The event marking the finalization of the provided measurement
     */
    private func finish(measurement: Int64) throws -> Event {
        let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
        let currentMeasurement = try persistenceLayer.load(measurementIdentifiedBy: measurement)
        currentMeasurement.synchronizable = true
        currentMeasurement.events.append(Event(time: Date(), type: .lifecycleStop, value: nil, measurement: currentMeasurement))
        let savedMeasurement = try persistenceLayer.save(measurement: currentMeasurement)

        guard let event = savedMeasurement.events.last else {
            fatalError()
        }

        return event
    }

    private func handle(event: DataCapturingEvent, status: Status) {
        handler.forEach { listener in
            listener(event, status)
        }
    }

    /// Provides the current time in milliseconds since january 1st 1970 (UTC).
    public static func currentTimeInMillisSince1970() -> UInt64 {
        return convertToUtcTimestamp(date: Date())
    }

    /// Converts a `Data` object to a UTC milliseconds timestamp since january 1st 1970.
    public static func convertToUtcTimestamp(date value: Date) -> UInt64 {
        return UInt64(value.timeIntervalSince1970*1000.0)
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
            // Make sure locations are in order.
            if let prevLocationUpdateTime = self.prevLocationUpdateTime {
                guard prevLocationUpdateTime < location.timestamp else {
                    os_log(.debug, log: DataCapturingService.log, "Skipping location update due to late location.")
                    continue
                }
            }
            self.prevLocationUpdateTime = location.timestamp

            let isValid = trackCleaner.isValid(location: location)
            let geoLocation = LocationCacheEntry(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                accuracy: location.horizontalAccuracy,
                speed: location.speed,
                timestamp: location.timestamp,
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

                    self.handle(event: .geoLocationAcquired(position: geoLocation), status: .success)
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
        os_log("Location service failed with error: %{public}@!", log: DataCapturingService.log, type: .error, error.localizedDescription)
        hasFix = false
    }
}

// TODO: Maybe remove this and split GeoLocation in one class storing all the data and another storing the reference to a measurement (in addition to a reference to the data storing class).
/**
 This struct exists to save time on a new location by just storing it away. It needs to be converted to a GeoLocation prior to persitent storage.

 - Author: Klemens Muthmann
 */
public struct LocationCacheEntry: Equatable, Hashable, CustomStringConvertible {
    /// The locations latitude coordinate as a value from -90.0 to 90.0 in south and north diretion.
    public let latitude: Double
    /// The locations longitude coordinate as a value from -180.0 to 180.0 in west and east direction.
    public let longitude: Double
    /// The estimated accuracy of the measurement in meters.
    public let accuracy: Double
    /// The speed the device was moving during the measurement in meters per second.
    public let speed: Double
    /// The time the measurement happened at.
    public let timestamp: Date
    /// Whether or not this is a valid location in a cleaned track.
    public let isValid: Bool

    /// A stringified version of this object. This should mostly be used for pretty printing during debugging.
    public var description: String {
        return """
        LocationCacheEntry(\
        latitude: \(latitude),\
        longitude: \(longitude),\
        accuracy: \(accuracy),\
        speed: \(speed),\
        timestamp: \(timestamp),\
        isValid: \(isValid))
        """
    }

    /**
     Add this object as a new `GeoLocation` to a `Track`, which becomes the parent track. After this operation, this entry should be appended as a new `GeoLocation` to the end of the `parent`.

     - Parameter parent: The `Track` to add this as a `GeoLocation` to
     */
    func storeAsGeoLocation(to parent: inout Track) throws {
        let location = GeoLocation(
            latitude: latitude,
            longitude: longitude,
            accuracy: accuracy,
            speed: speed,
            timestamp: DataCapturingService.convertToUtcTimestamp(date: timestamp),
            isValid: isValid,
            parent: parent)
        parent.locations.append(location)
    }
}