/*
 * Copyright 2023 Cyface GmbH
 *
 * This file is part of the Read-for-Robots iOS App.
 *
 * The Read-for-Robots iOS App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Read-for-Robots iOS App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Read-for-Robots iOS App. If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation
import DataCapturing
import OSLog
import SwiftUI
import Combine
import CoreLocation

/**
 The view model for the live view showing the current capturing session and providing buttons to control it.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - SeeAlso: ``LiveView``
 */
@MainActor
class LiveViewModel: ObservableObject {
    /// How to display the current speed of the user.
    @Published var speed: String
    /// How to display the average speed of the user.
    @Published var averageSpeed: String
    /// The state the active ``Measurement`` is in.
    @Published var measurementState: MeasurementState
    /// The current position in geographic coordinates of longitude and latitude.
    //@Published var lastCapturedLongitude: String
    //@Published var lastCapturedLatitude: String
    /// The name to display for this ``Measurement``.
    @Published var measurementName: String
    var dataStoreStack: DataStoreStack
    /// How to display the distance already travelled during this ``Measurement``.
    @Published var distance: String
    /// How to display the duration this ``Measurement`` has already taken.
    @Published var duration: String
    /// How to display the current rise during the active ``Measurement``.
    @Published var rise: String
    /// How to display the avoided emissions during the active ``Measurement``.
    @Published var avoidedEmissions: String
    @Published var hasLocationFix = Image(systemName: "location")
    /// The currently captured measurement or `nil` if no measurement is active.
    private var locations = [[GeoLocation]]()
    private var altitudes = [[DataCapturing.Altitude]]()
    private var dataStorageProcess: CapturedDataStorage
    var measurement: DataCapturing.Measurement {
        get {
            if let measurement = self._measurement {
                return measurement
            } else {
                let measurement = MeasurementImpl()

                registerLifecycleFlows(measurement)
                let locationsFlow = measurement.measurementMessages.filter { if case Message.capturedLocation = $0 { return true } else { return false } }.compactMap {if case let Message.capturedLocation(location) = $0 { return location } else { return nil }}
                locationsFlow.compactMap { location in "\(speedFormatter.string(from: location.speed as NSNumber) ?? "0.0") km/h" }.receive(on: RunLoop.main).assign(to: &$speed)

                let trackFlow = locationsFlow
                    .compactMap { [weak self] location in
                        let endIndex = max((self?.locations.count ?? 0)-1, 0)
                        self?.locations[endIndex].append(location)
                        return self?.locations
                    }
                let distanceFlow = trackFlow.map {(tracks: [[GeoLocation]]) in
                    return tracks.map { track in
                        var trackLength = 0.0
                        var prevLocation: GeoLocation? = nil
                        for location in track {
                            if let prevLocation = prevLocation {
                                trackLength += location.distance(from: prevLocation)
                            }
                            prevLocation = location
                        }
                        return trackLength
                    }.reduce(0.0) { accumulator, next in
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

                trackFlow.map { tracks in
                    RFR.averageSpeed(timelines: tracks)
                }
                .compactMap {
                    speedFormatter.string(from: $0 as NSNumber)
                }
                .map { formattedSpeed in
                    "\(formattedSpeed) km/h"
                }
                .receive(on: RunLoop.main)
                .assign(to: &$averageSpeed)

                trackFlow
                    .map { tracks in
                        return RFR.duration(timelines: tracks)
                    }
                    .compactMap {
                        timeFormatter.string(from: $0)
                    }
                    .receive(on: RunLoop.main)
                    .assign(to: &$duration)

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
                    .assign(to: &$rise)

                distanceFlow.map {
                    RFR.avoidedEmissions($0)
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
    private var _measurement: DataCapturing.Measurement?
    private var identifier: UInt64?
    private var cancellables = [AnyCancellable]()
    @Published var error: Error?
    
    init(
        speed: Double = 0.0,
        averageSpeed: Double = 0.0,
        measurementState: MeasurementState = .stopped,
        measurementName: String = "",
        distance: Double = 0.0,
        duration: TimeInterval = 0.0,
        rise: Double = 0.0,
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

        guard let formattedRise = riseFormatter.string(from: rise as NSNumber) else {
            fatalError()
        }

        self.speed = "\(formattedSpeed) km/h"
        self.averageSpeed = "\(averageFormattedSpeed) km/h"
        self.measurementState = measurementState
        self.measurementName = measurementName
        self.distance = "\(formattedDistance) km"
        self.duration = formattedDuration
        self.rise = "\(formattedRise) m"
        self.avoidedEmissions = "\(formattedAvoidedEmissions) g CO₂"
    }

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
        self.rise = "\(formattedRise) m"
        self.avoidedEmissions = "\(formattedAvoidedEmissions) g CO₂"
    }

    /**
     Called if the user presses the stop button.
     */
    func onStopPressed() {
        do {
            if measurement.isRunning || measurement.isPaused {
                try measurement.stop()
                self.dataStorageProcess.unsubscribe()
                cancellables.forEach { $0.cancel() }
                cancellables.removeAll(keepingCapacity: true)
                self._measurement = nil
            }
        } catch {
            self.error = error
        }
    }

    /**
     Called if the user presses the play/pause button.
     */
    func onPlayPausePressed() {
        do {
            if measurement.isRunning {
                try measurement.pause()
                dataStorageProcess.unsubscribe()
            } else if measurement.isPaused {
                if let identifier = self.identifier {
                    try self.dataStorageProcess.subscribe(
                        to: measurement,
                        identifier
                    ) {}

                    try measurement.resume()
                }
            } else {
                self.identifier = try self.dataStorageProcess.createMeasurement("BICYCLE")
                if let identifier = self.identifier {
                    try self.dataStorageProcess.subscribe(
                        to: measurement,
                        identifier
                    ) {}
                    self.measurementName = "Fahrt \(identifier)"
                    try measurement.start(inMode: "BICYCLE")
                }
            }
        } catch {
            self.error = error
        }
    }

    private func registerLifecycleFlows(_ measurement: DataCapturing.Measurement) {
        measurement.measurementMessages.filter { if case .hasFix = $0 { return true } else { return false }}.map { _ in Image(systemName: "location") }.receive(on: RunLoop.main).assign(to: &$hasLocationFix)
        measurement.measurementMessages.filter { if case .fixLost = $0 { return true } else { return false }}.map { _ in Image(systemName: "location.slash")}.receive(on: RunLoop.main).assign(to: &$hasLocationFix)
        let startedFlow = measurement.measurementMessages.filter { if case Message.started = $0 { return true } else { return false }}.map { _ in MeasurementState.running }
        startedFlow.receive(on: RunLoop.main).assign(to: &$measurementState)
        cancellables.append(startedFlow.sink { [weak self] _ in self?.locations.append([GeoLocation]())
            self?.altitudes.append([DataCapturing.Altitude]())
        })
        measurement.measurementMessages.filter { if case Message.paused = $0 { return true } else { return false }}.map { _ in MeasurementState.paused}.receive(on: RunLoop.main).assign(to: &$measurementState)
        let resumedFlow = measurement.measurementMessages.filter { if case Message.resumed = $0 { return true } else { return false }}.map { _ in MeasurementState.running}
        resumedFlow.receive(on: RunLoop.main).assign(to: &$measurementState)
        cancellables.append(resumedFlow.sink { [weak self] _ in
            self?.locations.append([GeoLocation]())
            self?.altitudes.append([DataCapturing.Altitude]())
        })
        let stoppedEvents = measurement.measurementMessages.filter { if case Message.stopped = $0 { return true} else { return false }}.map { _ in MeasurementState.stopped}
        cancellables.append(stoppedEvents.sink {[weak self] _ in
            self?.locations.removeAll(keepingCapacity: true)
        })
        stoppedEvents.receive(on: RunLoop.main).assign(to: &$measurementState)
    }

    private func currentMeasurementState() throws -> MeasurementState {
        try dataStoreStack.wrapInContextReturn { context in
            let request = MeasurementMO.fetchRequest()
            if let pausedMeasurement = try request.execute().first(where: {!$0.synchronizable && !$0.synchronized}) {
                return MeasurementState.paused
            } else {
                return MeasurementState.stopped
            }
        }
    }

    private func loadFromPaused() throws {
        try dataStoreStack.wrapInContext { context in
            let request = MeasurementMO.fetchRequest()
            guard let measurementMO = try request.execute().first(where: {!$0.synchronizable && !$0.synchronized}) else {
                return
            }
            let identifier = UInt64(measurementMO.identifier)

            let tracks = measurementMO.typedTracks()
            let distance = coveredDistance(tracks: tracks)
            self.identifier = UInt64(identifier)
            format(
                speed: 0.0,
                averageSpeed: RFR.averageSpeed(timelines: tracks),
                measurementState: .paused,
                measurementName: "Fahrt \(identifier)",
                distance: distance,
                duration: RFR.duration(timelines: tracks),
                rise: summedHeight(timelines: tracks),
                avoidedEmissions: RFR.avoidedEmissions(distance)
            )
        }
    }
}

/**
 All the states a measurement may be in. The UI decides which elements to show based on this state.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
enum MeasurementState {
    /// The ``Measurement`` is active at the moment.
    case running
    /// The ``Measurement`` is paused at the moment.
    case paused
    /// The ``Measurement`` is stopped. No ``Measurement`` is currently active.
    case stopped
}
