/*
 * Copyright 2017-2024 Cyface GmbH
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
 - Version: 2.0.0
 - Since: 12.0.0
 */
public protocol Measurement {
    // TODO: It should not be possible to send messages via this variable. So this should be a publisher instead of a PasstroughSubject
    /// A combine subject used to receive messages during data capturing and forwarding them, to whoever wants to listen.
    var measurementMessages: AnyPublisher<Message, Never> { get }
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

    /// The background queue used to capture data.
    private let capturingQueue: DispatchQueue

    /// An object that handles capturing of values from the smartphones sensors excluding geo locations (GPS, GLONASS, GALILEO, etc.).
    private let sensorCapturer: SensorCapturer

    private let locationCapturer: LocationCapturer

    // TODO: Switch to Combine --> Make this a publisher on its own. Will have to read up on how to achieve this.
    public var messagesSubject: PassthroughSubject<Message, Never>

    /**
     A queue used to synchronize calls to the lifecycle methods `start`, `pause`, `resume` and `stop`.
     Using such a queue prevents successiv calls to these methods to interrupt each other.
     */
    private let lifecycleQueue: DispatchQueue
    private var messageCancellable: AnyCancellable? = nil
    private var finishedEventCancellable: AnyCancellable? = nil

    // MARK: - Initializers

    /**
     Creates a new completely initialized `DataCapturingService` accessing data a certain amount of times per second.

     - Parameters:
        - capturingQueue: The background queue to run data capturing on, so the UI is not blocked.
        - locationManagerFactory: A factory creating a *CoreLocation* `LocationManager` on demand. This can also be used to inject a mock implementation.
     */
    public init(
        capturingQueue: DispatchQueue = DispatchQueue.global(qos: .userInitiated),
        locationManagerFactory: (() -> LocationManager) = {
            let manager = CLLocationManager()
            manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            manager.allowsBackgroundLocationUpdates = true
            manager.pausesLocationUpdatesAutomatically = false
            manager.activityType = .other
            manager.showsBackgroundLocationIndicator = true
            manager.distanceFilter = kCLDistanceFilterNone
            return manager
        }
    ) {
        self.capturingQueue = capturingQueue
        self.lifecycleQueue = DispatchQueue(label: "lifecycle")
        self.sensorCapturer = SensorCapturer(capturingQueue: capturingQueue)
        self.locationCapturer = LocationCapturer(lifecycleQueue: lifecycleQueue, locationManagerFactory: locationManagerFactory)
        messagesSubject = PassthroughSubject<Message, Never>()

        self.isRunning = false
        self.isPaused = false
    }



    // MARK: - Internal Support Methods

    /**
     Internal method for starting the capturing process. This can optionally take in a handler for events occuring during data capturing.

     - Throws:
     - `PersistenceError` If there is no current measurement.
     - Some unspecified errors from within CoreData.
     */
    func startCapturing() throws {
        // Preconditions
        guard !isRunning else {
            os_log(
                "DataCapturingService.startCapturing(): Trying to start DataCapturingService which is already running!",
                log: OSLog.capturing,
                type: .info
            )
            return
        }

        messageCancellable = locationCapturer.start().receive(on: lifecycleQueue).merge(
            with: sensorCapturer.start()
        ).subscribe(messagesSubject)

        self.isRunning = true
    }

    /**
     An internal helper method for stopping the capturing process.

     This method is a collection of all operations necessary during pause as well as stop.
     */
    func stopCapturing() {
        sensorCapturer.stop()
        locationCapturer.stop()
        isRunning = false
    }

    // TODO: Sensor Capturer should only handle one type of sensor and be instantiated four times. Once per sensor.
}

// MARK: - Measurement

extension MeasurementImpl: Measurement {
    public var measurementMessages: AnyPublisher<Message, Never> {
        return messagesSubject.eraseToAnyPublisher()
    }
    
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
                self.isPaused = false
            }

            try startCapturing()
            messagesSubject.send(.started(timestamp: Date()))
        }
    }

    /**
     Stops the currently running or paused data capturing process.

     - Throws: `DataCapturingError.notPaused` or `DataCapturingError.notRunning` if the measurement is not running or paused.
     */
    public func stop() throws {
        try lifecycleQueue.sync {

            guard isPaused || isRunning else {
                if !isPaused {
                    throw DataCapturingError.notPaused
                } else {
                    throw DataCapturingError.notRunning
                }
            }

            // Inform about stopped event
            stopCapturing()
            messagesSubject.send(completion: .finished)
            isPaused = false

            messagesSubject.send(.stopped(timestamp: Date()))
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

            stopCapturing()
            isPaused = true

            messagesSubject.send(.paused(timestamp: Date()))
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

            try startCapturing()
            isPaused = false
            isRunning = true

            messagesSubject.send(.resumed(timestamp: Date()))
        }
    }

    /**
     Changes the current mode of transportation of the measurement. This can happen if the user switches for example from a bicycle to a car.
     If the new modality is the same as the old one, the method returns without doing anything.

     - Parameter to: The modality context to switch to.
     */
    public func changeModality(to modality: String) {
        lifecycleQueue.sync {
            messagesSubject.send(.modalityChanged(to: modality))
        }
    }
}

/// Converts a `Data` object to a UTC milliseconds timestamp since january 1st 1970.
public func convertToUtcTimestamp(date value: Date) -> UInt64 {
    return UInt64(value.timeIntervalSince1970 * millisecondsInASecond)
}
/// Constant to convert between a timestamp in seconds and milliseconds.
let millisecondsInASecond: Double = 1_000.0
