/*
 * Copyright 2017-2023 Cyface GmbH
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

/**
This protocol defines a measurements data together with its lifecycle during data capturing.

 This is probably the most central part of the Cyface SDK for iOS, as it steers the actual data capturing.
 Data received from this process could be stored to a data storage using for example an implementation of `DataStoreStack`.
 It can also be transmitted to a Cyface data collector server using using an implementation of `UploadProcess`.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 12.0.0
 */
public protocol Measurement {
    /// A combine subject used to receive messages during data capturing and forwarding them, to whoever wants to listen.
    var measurementMessages: PassthroughSubject<Message, Never> { get }
    /// A flag to get information about whether this measurement is currently running (`true`) or not (`false`).
    var isRunning: Bool { get }
    /// A flag to get information about whether this measurement is currently paused (`true`) or not (`false`).
    var isPaused: Bool { get }
    /// Start this measurement.
    func start() throws
    /// Stop this measurement for sure in contrast to a pause you can not resume after stopping.
    /// This throws an exception if not currently running or paused.
    func stop() throws
    /// Pause this measurement and continue sometime in the future.
    /// This throws an exception if not currently running.
    func pause() throws
    /// Resume a paused measurement.
    /// This throws an exception if not currently paused.
    func resume() throws
    /// Switch the transportation mode of this measurement from now on.
    /// This can be used if the user for example switches from walking to public transport.
    ///
    /// - Parameter modality: The modality to switch to.
    func changeModality(to modality: String)
}

// TODO: Remove dead code from migration of location capturing to its own class
/**
 An object of this class handles the lifecycle of starting and stopping data capturing.
 
 - Author: Klemens Muthmann
 - Version: 10.2.0
 - Since: 1.0.0
 */
public class MeasurementImpl {

    // MARK: - Properties
    /// `true` if data capturing is running; `false` otherwise.
    public var isRunning: Bool

    /// `true` if data capturing was running but is currently paused; `false` otherwise.
    public var isPaused:Bool

    /**
     The *CoreData* stack used to store, retrieve and update captured data to the local system until the App can transmit it to a server.
     */
    //public let dataStoreStack: DataStoreStack

    // TODO: This should probably be carried out using an actor: See the talk "Protect mutable state with Swift actors" from WWDC 2021
    /// The background queue used to capture data.
    private let capturingQueue: DispatchQueue

    /// An object that handles capturing of values from the smartphones sensors excluding geo locations (GPS, GLONASS, GALILEO, etc.).
    private let sensorCapturer: SensorCapturer

    private let locationCapturer: LocationCapturer

    // TODO: Switch to Combine --> Make this a publisher on its own. Will have to read up on how to achieve this.
    /// A list of listeners that are notified of important events during data capturing.
    // public var handler = [((DataCapturingEvent, Status) -> Void)]()
    //@Published var mostRecentMessage: Message
    public var measurementMessages: PassthroughSubject<Message, Never>

    // TODO: This should probably be carried out using an actor: See the talk "Protect mutable state with Swift actors" from WWDC 2021
    /**
     A queue used to synchronize calls to the lifecycle methods `start`, `pause`, `resume` and `stop`.
     Using such a queue prevents successiv calls to these methods to interrupt each other.
     */
    private let lifecycleQueue: DispatchQueue

    // TODO: Handle via Combine
    /// The interval between data write opertions, during data capturing.
    //private let savingInterval: TimeInterval

    /// A timer called in regular intervals to save the captured data to the underlying database.
    //private var backgroundSynchronizationTimer: DispatchSourceTimer?
    //var fixSubjectCancellable: AnyCancellable?
    var messageCancellable: AnyCancellable? = nil

    // MARK: - Initializers

    /**
     Creates a new completely initialized `DataCapturingService` accessing data a certain amount of times per second.

     - Parameters:
        - capturingQueue: The background queue to run data capturing on, so the UI is not blocked.
        - locationManagerFactory: A factory creating a *CoreLocation* `LocationManager` on demand. This can also be used to inject a mock implementation.
     */
    public init(
        //lifecycleQueue: DispatchQueue,
        capturingQueue: DispatchQueue = DispatchQueue.global(qos: .userInitiated)/*,
        savingInterval: TimeInterval,
        dataStoreStack: DataStoreStack*/,
        locationManagerFactory: (() -> LocationManager) = {
            let manager = CLLocationManager()
            manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            manager.allowsBackgroundLocationUpdates = true
            manager.pausesLocationUpdatesAutomatically = false
            manager.activityType = .other
            manager.showsBackgroundLocationIndicator = true
            manager.distanceFilter = kCLDistanceFilterNone
            //manager.requestAlwaysAuthorization()
            return manager
        }
    ) {
        //self.dataStoreStack = dataStoreStack
        self.capturingQueue = capturingQueue
        self.lifecycleQueue = DispatchQueue(label: "lifecycle")
        self.sensorCapturer = SensorCapturer(/*lifecycleQueue: lifecycleQueue, */capturingQueue: capturingQueue)
        // TODO: Why does LocationCapturer still require the lifecycleQueue
        self.locationCapturer = LocationCapturer(lifecycleQueue: lifecycleQueue, locationManagerFactory: locationManagerFactory)
        measurementMessages = PassthroughSubject<Message, Never>()

        self.isRunning = false
        self.isPaused = false

        //self.savingInterval = savingInterval
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
    func startCapturing(/*savingEvery time: TimeInterval, for eventType: EventType*/) throws {
        // Preconditions
        guard !isRunning else {
            os_log(
                "DataCapturingService.startCapturing(): Trying to start DataCapturingService which is already running!",
                log: OSLog.capturing,
                type: .info
            )
            return
        }

        /*guard var measurement = capturedMeasurement else {
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
        }*/
        messageCancellable = locationCapturer.start().receive(on: lifecycleQueue).merge(
            with: sensorCapturer.start(/*measurement: measurement*/)
        ).subscribe(measurementMessages)



        // Start storage to database.
        /*let backgroundSynchronizationTimer = DispatchSource.makeTimerSource(queue: self.lifecycleQueue)
        backgroundSynchronizationTimer.setEventHandler(handler: saveCapturedData)
        backgroundSynchronizationTimer.schedule(deadline: .now(), repeating: time)
        backgroundSynchronizationTimer.activate()
        self.backgroundSynchronizationTimer = backgroundSynchronizationTimer*/

        self.isRunning = true
    }

    /**
     An internal helper method for stopping the capturing process.

     This method is a collection of all operations necessary during pause as well as stop.
     */
    func stopCapturing() {
        sensorCapturer.stop()
        locationCapturer.stop()
        /*backgroundSynchronizationTimer?.cancel()
        //if !locationsCache.isEmpty || !sensorCapturer.isEmpty {
        saveCapturedData()
        //}*/
        isRunning = false
        /*fixSubjectCancellable?.cancel()
        locationSubjectCancellable?.cancel()*/
    }

    // TODO: Storage should probably be handled by Sensor Capturer and Location Capturer via some strategy.
    // TODO: Sensor Capturer should only handle one type of sensor and be instantiated four times. Once per sensor.
    /**
     Method called by the `backgroundSynchronizationTimer` on each invocation.

     This method saves all data from `sensorCapturer` and from `locationsCapturer` caches to the underlying data storage (database and file system) and cleans both caches.
     */
    /*func saveCapturedData() {
        do {
            guard var currentMeasurement = self.capturedMeasurement else {
                os_log("No current measurement to save the location to! Data capturing impossible.", log: OSLog.capturing, type: .error)
                return
            }

            let localAccelerationsCache = sensorCapturer.accelerations
            let localRotationsCache = sensorCapturer.rotations
            let localDirectionsCache = sensorCapturer.directions
            let localAltitudesCache = sensorCapturer.altitudes
            let localLocationsCache = locationCapturer.locationsCache

            let persistenceLayer = dataStoreStack.persistenceLayer()

            currentMeasurement.tracks.last?.altitudes.append(contentsOf: localAltitudesCache)

            try persistenceLayer.save(locations: localLocationsCache, in: &currentMeasurement)

            try persistenceLayer.save(
                accelerations: localAccelerationsCache,
                rotations: localRotationsCache,
                directions: localDirectionsCache,
                in: &currentMeasurement)


            // TODO: Shouldn't cleaning these not happen directly after assigning them to local collections. In that case it is of course important to not empty the collection but to assign new, empty ones, to keep the local ones filled.
            sensorCapturer.accelerations.removeAll(keepingCapacity: true)
            sensorCapturer.rotations.removeAll(keepingCapacity: true)
            sensorCapturer.directions.removeAll(keepingCapacity: true)
            sensorCapturer.altitudes.removeAll(keepingCapacity: true)

            locationCapturer.locationsCache.removeAll(keepingCapacity: true)
        } catch let error {
            return os_log("Unable to save captured data. Error %{public}@", log: OSLog.capturing, type: .error, error.localizedDescription)
        }
    }*/

    /**
     Finishes the provided measurement if still open and marks this event in the list of events.
     This method does not check if the measurement is already finished, so be careful to only call it on non finished measurements.

     - Parameter measurement: The device wide unique identifier of the measurement to finish
     - Returns: The event marking the finalization of the provided measurement
     */
    /*private func finish(measurement: Int64) throws -> Event {
        let persistenceLayer = dataStoreStack.persistenceLayer()
        let currentMeasurement = try persistenceLayer.load(measurementIdentifiedBy: measurement)
        currentMeasurement.synchronizable = true
        currentMeasurement.events.append(Event(time: Date(), type: .lifecycleStop, value: nil, measurement: currentMeasurement))
        let savedMeasurement = try persistenceLayer.save(measurement: currentMeasurement)

        guard let event = savedMeasurement.events.last else {
            fatalError()
        }

        return event
    }*/

    /*private func handle(event: DataCapturingEvent, status: Status) {
        handler.forEach { listener in
            listener(event, status)
        }
    }*/
}

// MARK: - Measurement

extension MeasurementImpl: Measurement {
    /*public var capturedMeasurement: Measurement? {
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
    }*/
    /**
     Puts the `DataCapturingService` in the correct state according to the current database values.

     - Attention: This method must be called before calling any other method from the `DataCapturingService`
     */
    /*public func setup() {
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
    }*/

    /**
     Starts the capturing process.

     - Parameters:
        - modality: The mode of transportation to use for the newly created measurement. This should be something like "car" or "bicycle".
     */
    public func start() throws {
        try lifecycleQueue.sync {
            if isPaused {
                os_log(
                    """
Starting data capturing on paused service. Finishing paused measurements and starting fresh. This is probably the result of a lifecycle error.
""",
                    log: OSLog.capturing,
                    type: .error
                )
                /*if let currentMeasurement = currentMeasurement {
                    _ = try finish(measurement: currentMeasurement)
                }*/
                self.isPaused = false
            }

            /*let persistenceLayer = dataStoreStack.persistenceLayer()

            let measurement = try persistenceLayer.createMeasurement()

            self.currentMeasurement = measurement.identifier*/

            try startCapturing()
            /*if let event = try startCapturing(savingEvery: savingInterval, for: .lifecycleStart) {
                handle(event: .serviceStarted(measurement: measurement.identifier, event: event), status: .success)
            }*/
            // TODO: startCapturing to connect with persistenceLayer, SensorCapturer and LocationCapturer
            measurementMessages.send(.started(timestamp: Date()))
        }
    }

    /**
     Stops the currently running or paused data capturing process.

     - Throws: `DataCapturingError.notPaused` or `DataCapturingError.notRunning` if the measurement is not running or paused.
     */
    public func stop() throws {
        try lifecycleQueue.sync {
            /*guard let currentMeasurement = currentMeasurement else {
                os_log("Trying to stop a stopped service! Ignoring call to stop!", log: OSLog.capturing, type: .error)
                return
            }*/

            guard isPaused || isRunning else {
                if !isPaused {
                    throw DataCapturingError.notPaused
                } else {
                    throw DataCapturingError.notRunning
                }
            }

            // Inform about stopped event
            stopCapturing()
            /*let event = try finish(measurement: currentMeasurement)
            self.currentMeasurement = nil*/
            isPaused = false

            //self.handle(event: .serviceStopped(measurement: currentMeasurement, event: event), status: .success)
            measurementMessages.send(.stopped(timestamp: Date()))
            measurementMessages.send(completion: .finished)
            /*os_log(
                "Stopped data capturing service for measurement %{PUBLIC}d.",
                log: OSLog.capturing,
                type: .info,
                currentMeasurement
            )*/
        }
    }

    /**
     Pauses the current data capturing measurement for the moment. No data is captured until `resume()` has been called, but upon the call to `resume()` the last measurement will be continued instead of beginning a new now.

     - Throws: `DataCaturingError.notRunning` if the service was not running and thus pausing it makes no sense.
     - Throws: `DataCapturingError.isPaused` if the service was already paused and pausing it again makes no sense.
     */
    public func pause() throws {
        try lifecycleQueue.sync {
            guard isRunning else {
                throw DataCapturingError.notRunning
            }

            guard !isPaused else {
                throw DataCapturingError.isPaused
            }

            /*guard let currentMeasurement = currentMeasurement else {
                fatalError("No current measurement available in paused state!")
            }*/

            stopCapturing()
            isPaused = true

            /*let persistenceLayer = dataStoreStack.persistenceLayer()
            var measurement = try persistenceLayer.load(measurementIdentifiedBy: currentMeasurement)
            let event = try persistenceLayer.createEvent(of: .lifecyclePause, parent: &measurement)*/

            //handle(event: .servicePaused(measurement: currentMeasurement, event: event), status: .success)
            measurementMessages.send(.paused(timestamp: Date()))
            //measurementMessages.send(completion: .finished)
            //messageCancellable = nil
            /*os_log(
                "Paused data capturing service for measurement ${PUBLIC}d.\nDistance Covered: %{PUBLIC}f",
                log: OSLog.capturing,
                type: .info,
                measurement.identifier,
                measurement.trackLength
            )*/
        }
    }

    /**
     Resumes the current data capturing with the data capturing measurement that was running when `pause()` was called. A call to this method is only valid after a call to `pause()`. It is going to fail if used after `start()` or `stop()`.

     - Throws: `DataCapturingError.notPaused`: If the service was not paused and thus resuming it makes no sense.
     - Throws: `DataCapturingError.isRunning`: If the service was running and thus resuming it makes no sense.
     - Throws: `DataCapturingError.noCurrentMeasurement`: If no current measurement is available while resuming data capturing.
     */
    public func resume() throws {
        try lifecycleQueue.sync {
            guard isPaused else {
                throw DataCapturingError.notPaused
            }

            guard !isRunning else {
                throw DataCapturingError.isRunning
            }

            /*guard let currentMeasurement = currentMeasurement else {
                fatalError("No measurement to resume")
            }*/

            //if let startEvent = try startCapturing(savingEvery: savingInterval, for: .lifecycleResume) {
            try startCapturing()
            isPaused = false
            isRunning = true

                //handle(event: .serviceResumed(measurement: currentMeasurement, event: startEvent), status: .success)
            measurementMessages.send(.resumed(timestamp: Date()))
            //messageCancellable?.cancel()
            //messageCancellable = nil
                /*os_log("Resumed data capturing service for measurement %{PUBLIC}d.",
                       log: OSLog.capturing,
                       type: .info,
                       currentMeasurement)*/
            //}
        }
    }

    /**
     Changes the current mode of transportation of the measurement. This can happen if the user switches for example from a bicycle to a car.
     If the new modality is the same as the old one, the method returns without doing anything.

     - Parameter to: The modality context to switch to.
     */
    public func changeModality(to modality: String) {
        lifecycleQueue.sync {
            /*guard let currentMeasurementIdentifier = currentMeasurement else {
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
            }*/
            measurementMessages.send(.modalityChanged(to: modality))
        }
    }
}

/// Converts a `Data` object to a UTC milliseconds timestamp since january 1st 1970.
func convertToUtcTimestamp(date value: Date) -> UInt64 {
    return UInt64(value.timeIntervalSince1970 * millisecondsInASecond)
}
/// Constant to convert between a timestamp in seconds and milliseconds.
let millisecondsInASecond: Double = 1_000.0
