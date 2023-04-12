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
import Combine
import os.log

public protocol DataCapturingService {
    var currentMeasurement: Int64? { get }
    var capturedMeasurement: Measurement? { get }
    var dataStoreStack: DataStoreStack { get }
    var handler: [((DataCapturingEvent, Status) -> Void)] { get set }
    var isRunning: Bool { get }
    var isPaused: Bool { get }
    func setup()
    func start(inMode modality: String) throws
    func stop() throws
    func pause() throws
    func resume() throws
    func changeModality(to modality: String)
}

// TODO: Remove dead code from migration of location capturing to its own class
/**
 An object of this class handles the lifecycle of starting and stopping data capturing.
 
 - Author: Klemens Muthmann
 - Version: 10.2.0
 - Since: 1.0.0
 */
public class DataCapturingServiceImpl {

    // MARK: - Properties
    /// `true` if data capturing is running; `false` otherwise.
    public var isRunning = false

    /// `true` if data capturing was running but is currently paused; `false` otherwise.
    public var isPaused = false

    // TODO: This should probably be a Measurement which is checked for fault on each call. In addition it might be a good idea to merge the DataCapturingService into the MeasurementMO class, since it only represents the behaviour of the measurement
    /// The currently recorded `Measurement` or `nil` if there is no active recording.
    public var currentMeasurement: Int64?
    /**
     The *CoreData* stack used to store, retrieve and update captured data to the local system until the App can transmit it to a server.
     */
    public let dataStoreStack: DataStoreStack

    // TODO: This should probably be carried out using an actor: See the talk "Protect mutable state with Swift actors" from WWDC 2021
    /// The background queue used to capture data.
    private let capturingQueue = DispatchQueue.global(qos: .userInitiated)

    /// An object that handles capturing of values from the smartphones sensors excluding geo locations (GPS, GLONASS, GALILEO, etc.).
    private let sensorCapturer: SensorCapturer

    private let locationCapturer: LocationCapturer

    /// A list of listeners that are notified of important events during data capturing.
    public var handler = [((DataCapturingEvent, Status) -> Void)]()

    // TODO: This should probably be carried out using an actor: See the talk "Protect mutable state with Swift actors" from WWDC 2021
    /**
     A queue used to synchronize calls to the lifecycle methods `start`, `pause`, `resume` and `stop`.
     Using such a queue prevents successiv calls to these methods to interrupt each other.
     */
    private let lifecycleQueue = DispatchQueue(label: "lifecylce")

    /// The interval between data write opertions, during data capturing.
    private let savingInterval: TimeInterval

    /// A timer called in regular intervals to save the captured data to the underlying database.
    private var backgroundSynchronizationTimer: DispatchSourceTimer?
    var fixSubjectCancellable: AnyCancellable?
    var locationSubjectCancellable: AnyCancellable?

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
        lifecycleQueue: DispatchQueue,
        capturingQueue: DispatchQueue,
        savingInterval: TimeInterval,
        dataStoreStack: DataStoreStack
    ) {
        self.dataStoreStack = dataStoreStack
        self.sensorCapturer = SensorCapturer(lifecycleQueue: lifecycleQueue, capturingQueue: capturingQueue)
        self.locationCapturer = LocationCapturer(lifecycleQueue: lifecycleQueue)
        self.savingInterval = savingInterval
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
            os_log(
                "DataCapturingService.startCapturing(): Trying to start DataCapturingService which is already running!",
                log: OSLog.capturing,
                type: .info
            )
            return nil
        }

        guard var measurement = capturedMeasurement else {
            throw DataCapturingError.noCurrentMeasurement
        }

        // TODO: Why do I need the persistence layer here? It should be possible to create the new track and event directly inside the measurement. Saving it should happen on the first saving run.
        let persistenceLayer = dataStoreStack.persistenceLayer()
        try persistenceLayer.appendNewTrack(to: &measurement)
        let event = try persistenceLayer.createEvent(of: eventType, parent: &measurement)

        // Start the actual sensors.
        self.fixSubjectCancellable = locationCapturer.fixSubject.sink { [weak self] hasFix in
            self?.handle(event: hasFix ? DataCapturingEvent.geoLocationFixAcquired: DataCapturingEvent.geoLocationFixLost, status: .success)
        }
        self.locationSubjectCancellable = locationCapturer.locationSubject.sink { [weak self] location in
            self?.handle(event: .geoLocationAcquired(position: location), status: .success)
        }
        locationCapturer.start()
        sensorCapturer.start(measurement: measurement)

        // Start storage to database.
        let backgroundSynchronizationTimer = DispatchSource.makeTimerSource(queue: self.lifecycleQueue)
        backgroundSynchronizationTimer.setEventHandler(handler: saveCapturedData)
        backgroundSynchronizationTimer.schedule(deadline: .now(), repeating: time)
        backgroundSynchronizationTimer.activate()
        self.backgroundSynchronizationTimer = backgroundSynchronizationTimer

        self.isRunning = true
        return event
    }

    /**
     An internal helper method for stopping the capturing process.
     */
    func stopCapturing() {
        sensorCapturer.stop()
        locationCapturer.stop()
        backgroundSynchronizationTimer?.cancel()
        //if !locationsCache.isEmpty || !sensorCapturer.isEmpty {
        saveCapturedData()
        //}
        isRunning = false
        fixSubjectCancellable?.cancel()
        locationSubjectCancellable?.cancel()
    }

    // TODO: Storage should probably be handled by Sensor Capturer and Location Capturer via some strategy.
    // TODO: Sensor Capturer should only handle one type of sensor and be instantiated four times. Once per sensor.
    /**
     Method called by the `backgroundSynchronizationTimer` on each invocation.

     This method saves all data from `sensorCapturer` and from `locationsCapturer` caches to the underlying data storage (database and file system) and cleans both caches.
     */
    func saveCapturedData() {
        do {
            guard let currentMeasurement = self.currentMeasurement else {
                os_log("No current measurement to save the location to! Data capturing impossible.", log: OSLog.capturing, type: .error)
                return
            }

            let localAccelerationsCache = sensorCapturer.accelerations
            let localRotationsCache = sensorCapturer.rotations
            let localDirectionsCache = sensorCapturer.directions
            let localAltitudesCache = sensorCapturer.altitudes
            let localLocationsCache = locationCapturer.locationsCache

            let persistenceLayer = dataStoreStack.persistenceLayer()
            var measurement = try persistenceLayer.load(measurementIdentifiedBy: currentMeasurement)

            try persistenceLayer.save(locations: localLocationsCache, in: &measurement)

            try persistenceLayer.save(
                accelerations: localAccelerationsCache,
                rotations: localRotationsCache,
                directions: localDirectionsCache,
                in: &measurement)

            // TODO: Shouldn't cleaning these not happen directly after assigning them to local collections. In that case it is of course important to not empty the collection but to assign new, empty ones, to keep the local ones filled.
            sensorCapturer.accelerations.removeAll(keepingCapacity: true)
            sensorCapturer.rotations.removeAll(keepingCapacity: true)
            sensorCapturer.directions.removeAll(keepingCapacity: true)
            sensorCapturer.altitudes.removeAll(keepingCapacity: true)

            locationCapturer.locationsCache.removeAll(keepingCapacity: true)
        } catch let error {
            return os_log("Unable to save captured data. Error %{public}@", log: OSLog.capturing, type: .error, error.localizedDescription)
        }
    }

    /**
     Finishes the provided measurement if still open and marks this event in the list of events.
     This method does not check if the measurement is already finished, so be careful to only call it on non finished measurements.

     - Parameter measurement: The device wide unique identifier of the measurement to finish
     - Returns: The event marking the finalization of the provided measurement
     */
    private func finish(measurement: Int64) throws -> Event {
        let persistenceLayer = dataStoreStack.persistenceLayer()
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
}

// MARK: - DataCapturingService

extension DataCapturingServiceImpl: DataCapturingService {
    public var capturedMeasurement: Measurement? {
        let persistenceLayer = dataStoreStack.persistenceLayer()
        if let currentMeasurement = currentMeasurement {
            do {
                return try persistenceLayer.load(measurementIdentifiedBy: currentMeasurement)
            } catch {
                return nil
            }
        } else {
            return nil
        }
    }
    /**
     Puts the `DataCapturingService` in the correct state according to the current database values.

     - Attention: This method must be called before calling any other method from the `DataCapturingService`
     */
    public func setup() {
        let persistenceLayer = dataStoreStack.persistenceLayer()

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
            // TODO: Probably rather throw some kind of error here.
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
                    log: OSLog.capturing,
                    type: .error
                )
                if let currentMeasurement = currentMeasurement {
                    _ = try finish(measurement: currentMeasurement)
                }
                self.isPaused = false
            }

            let persistenceLayer = dataStoreStack.persistenceLayer()

            let measurement = try persistenceLayer.createMeasurement()

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
                os_log("Trying to stop a stopped service! Ignoring call to stop!", log: OSLog.capturing, type: .error)
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
            os_log(
                "Stopped data capturing service for measurement %{PUBLIC}d.",
                log: OSLog.capturing,
                type: .info,
                currentMeasurement
            )
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
            let persistenceLayer = dataStoreStack.persistenceLayer()
            var measurement = try persistenceLayer.load(measurementIdentifiedBy: currentMeasurement)
            let event = try persistenceLayer.createEvent(of: .lifecyclePause, parent: &measurement)

            handle(event: .servicePaused(measurement: currentMeasurement, event: event), status: .success)
            os_log(
                "Paused data capturing service for measurement ${PUBLIC}d.\nDistance Covered: %{PUBLIC}f",
                log: OSLog.capturing,
                type: .info,
                measurement.identifier,
                measurement.trackLength
            )
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
                       log: OSLog.capturing,
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

            let persistenceLayer = dataStoreStack.persistenceLayer()

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
    /// Ellipsoidal Altitude in meters
    public let altitude: Double
    /// The estimated accuracy of the measurement in meters.
    public let accuracy: Double
    /// The accuracy of altitude calculations in meters.
    public let verticalAccuracy: Double
    /// The speed the device was moving during the measurement in meters per second.
    public let speed: Double
    /// The time the measurement happened at.
    public let time: Date
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
        timestamp: \(time.debugDescription),\
        isValid: \(isValid)),\
        altitude: \(altitude),\
        verticalAccuracy: \(verticalAccuracy))
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
            time: time,
            isValid: isValid,
            altitude: altitude,
            verticalAccuracy: verticalAccuracy,
            parent: parent)
        parent.locations.append(location)
    }
}


// TODO: Remove these two if not necessary any more.
/// Provides the current time in milliseconds since january 1st 1970 (UTC).
/*public func currentTimeInMillisSince1970() -> UInt64 {
    return convertToUtcTimestamp(date: Date())
}*/

/// Converts a `Data` object to a UTC milliseconds timestamp since january 1st 1970.
func convertToUtcTimestamp(date value: Date) -> UInt64 {
    return UInt64(value.timeIntervalSince1970 * millisecondsInASecond)
}
/// Constant to convert between a timestamp in seconds and milliseconds.
let millisecondsInASecond: Double = 1_000.0
