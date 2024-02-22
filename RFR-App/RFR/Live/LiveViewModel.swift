/*
 * Copyright 2023 Cyface GmbH
 *
 * This file is part of the Ready for Robots iOS App.
 *
 * The Ready for Robots iOS App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Ready for Robots iOS App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Ready for Robots iOS App. If not, see <http://www.gnu.org/licenses/>.
 */
import Foundation
import DataCapturing
import OSLog
import SwiftUI
import Combine
import CoreLocation

/**
 The view model for the live view showing the current capturing session and providing buttons to control it.

 This class is responsbile for creating all the objects required during a ``Measurement`` and connecting those objects using the Combine framework. After a pause or a stop command all Combine connections are removed.

 The most important connections are the ones to the published properties, used by the ``LiveView`` and the ones to a ``CapturedDataStorage`` for saving all captured data to the provided ``DataStoreStack``.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.2
 - SeeAlso: ``LiveView``
 */
class LiveViewModel: ObservableObject {
    /// How to display the current speed of the user.
    @Published var speed: String
    /// How to display the average speed of the user.
    @Published var averageSpeed: String
    /// The state the active ``Measurement`` is in.
    @Published var measurementState: MeasurementState
    /// The name to display for this ``Measurement``.
    @Published var measurementName: String
    /// How to display the distance already travelled during this ``Measurement``.
    @Published var distance: String
    /// How to display the duration this ``Measurement`` has already taken.
    @Published var duration: String
    /// How to display the current inclination during the active ``Measurement``.
    @Published var inclination: String
    /// How to display the avoided emissions during the active ``Measurement``.
    @Published var avoidedEmissions: String
    /// Access to the underlying data store.
    private var dataStoreStack: DataStoreStack
    /// The geo locations captured during the current ``Measurement``. This is an array of arrays to represent different tracks separated by pauses.
    private var locations = [[GeoLocation]]()
    /// The altitudes captured during the current ``Measurement``. This is an array of arrays to represent different tracks seperated by pauses.
    private var altitudes = [[DataCapturing.Altitude]]()
    /// The ``CapturedDataStorage`` used to save data arriving from the current ``Measurement``to a ``DataStoreStack``
    private var dataStorageProcess: CapturedDataStorage
    /// The current ``Measurement`` presented by the current ``LiveView``.
    var measurement: DataCapturing.Measurement {
        get {
            if let measurement = self._measurement {
                return measurement
            } else {
                let measurement = MeasurementImpl()
                measurement.measurementMessages
                    .receive(on: DispatchQueue.main)
                    .assign(to: &$message)

                registerLifecycleFlows(measurement)
                // Only location captured events
                let locationsFlow = measurement.measurementMessages.filter { if case Message.capturedLocation = $0 { return true } else { return false } }.compactMap {if case let Message.capturedLocation(location) = $0 { return location } else { return nil }}
                // Use the most recent location to provide the speed value
                locationsFlow.filter {location in location.speed >= 0.0 }.compactMap { location in "\(speedFormatter.string(from: location.speed as NSNumber) ?? "0.0") km/h" }.receive(on: RunLoop.main).assign(to: &$speed)

                // Organize all received locations into the local locations array, and stream that array for further processing
                let trackFlow = locationsFlow
                    .compactMap { [weak self] location in
                        let endIndex = max((self?.locations.count ?? 0)-1, 0)
                        self?.locations[endIndex].append(location)
                        return self?.locations
                    }
                // Calculate and store distance covered, by all the tracks from the current measurement.
                let distanceFlow = trackFlow.map {(tracks: [[GeoLocation]]) in
                    return tracks
                        .map { track in
                            var trackLength = 0.0
                            var prevLocation: GeoLocation? = nil
                            for location in track {
                                if let prevLocation = prevLocation {
                                    trackLength += location.distance(from: prevLocation)
                                }
                                prevLocation = location
                            }
                            return trackLength
                        }
                        .reduce(0.0) { accumulator, next in
                            accumulator + next
                        }
                }
                distanceFlow.compactMap {
                    distanceFormatter.string(from: $0 as NSNumber)
                }.map { formattedDistance in
                    "\(formattedDistance) km"
                }
                .receive(on: RunLoop.main)
                .assign(to: &$distance)

                // Calculate and store average speed over all the tracks from this measurement.
                trackFlow.map { tracks in
                    Statistics.averageSpeed(timelines: tracks)
                }
                .filter { $0 >= 0.0}
                .compactMap {
                    speedFormatter.string(from: $0 as NSNumber)
                }
                .map { formattedSpeed in
                    "\(formattedSpeed) km/h"
                }
                .receive(on: RunLoop.main)
                .assign(to: &$averageSpeed)

                // Calculate and store the total duration for all the tracks in this measurement.
                trackFlow
                    .map { tracks in
                        return Statistics.duration(timelines: tracks)
                    }
                    .compactMap {
                        timeFormatter.string(from: $0)
                    }
                    .receive(on: RunLoop.main)
                    .assign(to: &$duration)

                // Calculate the total rise for all the tracks in this measurement.
                measurement.measurementMessages
                    .filter {
                        if case Message.capturedAltitude = $0 {
                            return true
                        } else {
                            return false
                        }
                    }
                    .compactMap { message in
                        if case let Message.capturedAltitude(altitude) = message {
                            return altitude
                        } else {
                            return nil
                        }
                    }
                    .compactMap { [weak self] (altitude: DataCapturing.Altitude) in
                        let endIndex = max((self?.altitudes.count ?? 0)-1, 0)
                        self?.altitudes[endIndex].append(altitude)
                        return self?.altitudes
                    }
                    .map { (tracks: [[DataCapturing.Altitude]]) in
                        return tracks.map { track in
                            os_log("Using altimeter values to calculate accumulated height.", log: OSLog.measurement, type: .debug)
                            var previousAltitude: Double? = nil
                            var sum = 0.0
                            for altitude in track {
                                if let previousAltitude = previousAltitude {
                                    let relativeAltitudeChange = altitude.relativeAltitude - previousAltitude
                                    if relativeAltitudeChange > 0.1 {
                                        sum += relativeAltitudeChange
                                    }
                                }
                                previousAltitude = altitude.relativeAltitude
                            }
                            return sum
                            //}
                        }
                        .reduce(0.0) { accumulator, next in
                            accumulator + next
                        }
                    }
                    .compactMap {
                        riseFormatter.string(from: $0 as NSNumber)
                    }
                    .map { formattedRise in
                        "\(formattedRise) m"
                    }
                    .receive(on: RunLoop.main)
                    .assign(to: &$inclination)

                // 
                distanceFlow.map {
                    Statistics.avoidedEmissions($0)
                }
                .compactMap {
                    emissionsFormatter.string(from: $0 as NSNumber)
                }
                .map { formattedEmissions in
                    "\(formattedEmissions) g CO₂"
                }
                .receive(on: RunLoop.main)
                .assign(to: &$avoidedEmissions)

                self._measurement = measurement
                return measurement
            }
        }
    }
    /// The internal cache for the ``Measurement`` currently running.
    private var _measurement: DataCapturing.Measurement?
    /// The identifier of the currently captured ``Measurement``
    private var identifier: UInt64?
    /// Store all the running *Combine* process, while they run.
    private var cancellables = [AnyCancellable]()
    /// Captures and publishes any error produced by this model.
    @Published var error: Error?
    /// Always contains the most recent message received from the Cyface SDK.
    @Published var message: Message = Message.receivedNothingYet

    /**
     Initialize an object of this class.

     By default most of the parameters are set to some default null value.
     However you must provide a ``DataStoreStack`` to store the data captured during a ``Measurement`` as well as the interval for how often to save captured data.

     - Parameter speed: How to display the current speed of the user.
     - Parameter averageSpeed: How to display the average speed of the user.
     - Parameter measurementState: The state the active ``Measurement`` is in.
     - Parameter measurementName: The name to display for this ``Measurement``.
     - Parameter distance: How to display the distance already travelled during this ``Measurement``.
     - Parameter duration: How to display the duration this ``Measurement`` has already taken.
     - Parameter inclination: How to display the current inclination during the active ``Measurement``.
     - Parameter avoidedEmissions: How to display the avoided emissions during the active ``Measurement``.
     - Parameter dataStoreStack: Access to the underlying data store.
     - Parameter dataStorageInterval: The time in seconds of how often to store data to the `dataStoreStack`. Data captured in between is queued and then bulk inserted.
     */
    init(
        speed: Double = 0.0,
        averageSpeed: Double = 0.0,
        measurementState: MeasurementState = .stopped,
        measurementName: String = "",
        distance: Double = 0.0,
        duration: TimeInterval = 0.0,
        inclination: Double = 0.0,
        avoidedEmissions: Double = 0.0,
        dataStoreStack: DataStoreStack,
        dataStorageInterval: Double
    ) {
        self.dataStorageProcess = CapturedCoreDataStorage(dataStoreStack, dataStorageInterval)
        self.dataStoreStack = dataStoreStack
        guard let formattedSpeed = speedFormatter.string(from: speed as NSNumber) else {
            fatalError()
        }

        guard let averageFormattedSpeed = speedFormatter.string(from: averageSpeed as NSNumber) else {
            fatalError()
        }

        guard let formattedAvoidedEmissions = emissionsFormatter.string(from: avoidedEmissions as NSNumber) else {
            fatalError()
        }

        guard let formattedDistance = distanceFormatter.string(from: distance as NSNumber) else {
            fatalError()
        }

        guard let formattedDuration = timeFormatter.string(from: duration) else {
            fatalError()
        }

        guard let formattedInclination = riseFormatter.string(from: inclination as NSNumber) else {
            fatalError()
        }

        self.speed = "\(formattedSpeed) km/h"
        self.averageSpeed = "\(averageFormattedSpeed) km/h"
        self.measurementState = measurementState
        self.measurementName = measurementName
        self.distance = "\(formattedDistance) km"
        self.duration = formattedDuration
        self.inclination = "\(formattedInclination) m"
        self.avoidedEmissions = "\(formattedAvoidedEmissions) g CO₂"
    }

    /// Formats all the live statistics so they can be displayed nicely.
    private func format(
        speed: Double,
        averageSpeed: Double,
        measurementState: MeasurementState,
        measurementName: String,
        distance: Double,
        duration: TimeInterval,
        rise: Double,
        avoidedEmissions: Double
    ) {
        guard let formattedSpeed = speedFormatter.string(from: speed as NSNumber) else {
            fatalError()
        }

        guard let averageFormattedSpeed = speedFormatter.string(from: averageSpeed as NSNumber) else {
            fatalError()
        }

        guard let formattedAvoidedEmissions = emissionsFormatter.string(from: avoidedEmissions as NSNumber) else {
            fatalError()
        }

        guard let formattedDistance = distanceFormatter.string(from: distance as NSNumber) else {
            fatalError()
        }

        guard let formattedDuration = timeFormatter.string(from: duration) else {
            fatalError()
        }

        guard let formattedRise = riseFormatter.string(from: rise as NSNumber) else {
            fatalError()
        }

        self.speed = "\(formattedSpeed) km/h"
        self.averageSpeed = "\(averageFormattedSpeed) km/h"
        self.measurementState = measurementState
        self.measurementName = measurementName
        self.distance = "\(formattedDistance) km"
        self.duration = formattedDuration
        self.inclination = "\(formattedRise) m"
        self.avoidedEmissions = "\(formattedAvoidedEmissions) g CO₂"
    }

    /**
     Called if the user presses the stop button.
     */
    func onStopPressed() throws {
        if measurement.isRunning || measurement.isPaused {
            try measurement.stop()
            self.cancellables.forEach {
                $0.cancel()
            }
            self.cancellables.removeAll(keepingCapacity: true)
            self._measurement = nil
            self.dataStorageProcess.unsubscribe()
        }
    }

    /**
     Called if the user presses the play button.
     */
    func onPlayPressed() throws {
        if measurement.isPaused {
            if let identifier = identifier {
                try dataStorageProcess.subscribe(
                    to: measurement,
                    identifier
                ) {}

                try measurement.resume()
            }
        } else if !measurement.isPaused && !measurement.isRunning{ // Is stopped
            identifier = try dataStorageProcess.createMeasurement("BICYCLE")
            if let identifier = identifier {
                try dataStorageProcess.subscribe(
                    to: measurement,
                    identifier
                ) {}
                measurementName = String(localized: "measurement \(identifier)", comment: "Title label of a running measurement.")
                try measurement.start()
            }
        }
    }

    /// Called if the user presses the pause button.
    func onPausePressed() throws {
        if measurement.isRunning {
            try measurement.pause()
        }
    }

    /// Register all the Combine flows required to capture lifecycle events such as `start`, `stop`, `pause` and `resume`.
    private func registerLifecycleFlows(_ measurement: DataCapturing.Measurement) {
        startFlow(measurement)
        pauseFlow(measurement)
        resumeFlow(measurement)
        stopFlow(measurement)

    }

    /// Setup Combine flow to handle ``Measurement`` start events.
    private func startFlow(_ measurement: DataCapturing.Measurement) {
        // Setting state
        let startedFlow = measurement.measurementMessages
            .filter { if case Message.started = $0 { return true } else { return false }}
            .map { _ in MeasurementState.running }
        startedFlow
            .receive(on: RunLoop.main)
            .assign(to: &$measurementState)
        // Append collections for the first track
        startedFlow
            .sink { [weak self] _ in
                self?.locations.append([GeoLocation]())
                self?.altitudes.append([DataCapturing.Altitude]())
            }
            .store(in: &cancellables)
    }

    /// Setup Combine flow to handle ``Measurement`` pause events.
    private func pauseFlow(_ measurement: DataCapturing.Measurement) {
        // Handle pause event
        measurement.measurementMessages
            .filter { if case Message.paused = $0 { return true } else { return false }}
            .map { _ in MeasurementState.paused}
            .receive(on: RunLoop.main)
            .assign(to: &$measurementState)
    }

    /// Setup Combine flow to handle ``Measurement`` resume events.
    private func resumeFlow(_ measurement: DataCapturing.Measurement) {
        let resumedFlow = measurement.measurementMessages
            .filter { if case Message.resumed = $0 { return true } else { return false }}
            .map { _ in MeasurementState.running}
        resumedFlow
            .receive(on: RunLoop.main).assign(to: &$measurementState)
        // Append collections for the next track
        resumedFlow
            .sink { [weak self] _ in
                self?.locations.append([GeoLocation]())
                self?.altitudes.append([DataCapturing.Altitude]())
            }
            .store(in: &cancellables)
    }

    /// Setup Combine flow to handle ``Measurement`` stop events.
    private func stopFlow(_ measurement: DataCapturing.Measurement) {
        let stoppedEvents = measurement.measurementMessages
            .filter { if case Message.stopped = $0 { return true} else { return false }}
            .map { _ in MeasurementState.stopped}
        // Setting state
        stoppedEvents
            .receive(on: RunLoop.main)
            .assign(to: &$measurementState)
        // Clean state of this model.
        // Clear storage for altitudes and locations.
        stoppedEvents
            .sink {[weak self] _ in
                os_log("Cleanup after Stop.")

                self?.locations.removeAll(keepingCapacity: true)
                self?.altitudes.removeAll(keepingCapacity: true)
            }
            .store(in: &cancellables)

    }
}

/**
 All the states a measurement may be in. The UI decides which elements to show based on this state.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.2
 */
enum MeasurementState {
    /// The ``Measurement`` is active at the moment.
    case running
    /// The ``Measurement`` is paused at the moment.
    case paused
    /// The ``Measurement`` is stopped. No ``Measurement`` is currently active.
    case stopped
}
