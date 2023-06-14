/*
 * Copyright 2022 Cyface GmbH
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
import CoreData
import OSLog

// TODO: There probably need to be two kinds of Measurement instances (and other objects in that hierarchy). One is used to create new instances and one is used for already synchronized ones. The reason is, that refreshing the objectId via the context does not work, as the context changes the objectId as soon as a call to context.save() happens. -.-
/**
 Instances of this class represent a single data capturing session, framed by calls to `DataCapturingService.start` and `DataCapturingService.stop`.

 Initially this is not going to be saved via CoreData. As soon as you call an appropriate save method on the `PersistenceLayer` the object is stored to CoreData and this objects `objectId` will receive a value.

 A `Measurement` can be synchronized to a Cyface server via an instance of `Synchronizer`.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - since: 11.0.0
 */
public class FinishedMeasurement: Hashable, Equatable {
    /// The minimum number of meters before the ascend is increased, to filter sensor noise.
    //public static let ascendThresholdMeters = 2.0
    /// The minimum accuracy in meters for GNSS altitudes to be used in ascend calculation.
    //public static let verticalAccuracyThresholdMeters = 12.0
    /// A device wide unique identifier for this measurement. Usually set by incrementing a counter.
    public let identifier: UInt64
    /// A flag, marking this `Measurement` as either ready for data syncrhonization or not.
    public var synchronizable: Bool
    /// A flag, marking this `Measurement` as either synchronized or not.
    public var synchronized: Bool
    /// The time when this measurement was started.
    public let time: Date
    /// The calculated length of the `Measurement`. See `DistanceCalculationStrategy` for further details.
    public var trackLength: Double {
        return tracks.map { track in
            return track.locations
        }
        .map { locations in
            var prevLocation: GeoLocation?
            var ret = 0.0
            locations.forEach { location in
                ret += prevLocation?.distance(from: location) ?? 0.0
                prevLocation = location
            }
            return 0.0
        }
        .reduce(0.0) { accumulator, partSum in
            accumulator + partSum
        }
    }
    /// The user events that occurred during this `Measurement`.
    public var events: [Event]
    /// The tracks containing all the data this `Measurement` has captured.
    public var tracks: [Track]
    public let accelerationDate: Data
    public let rotationData: Data
    public let directionData: Data

    /**
     Initialize a new `Measurement` from an existing CoreData managed object.

     After calling this initializer, this objects `objectId` is going to be set to the managed objects `objectId`.

     - parameter managedObject: The managed CoreData object to initialize this `Measurement` from.
     - throws: `InconstantData.locationOrderViolation` if the timestamps of the locations in this measurement are not strongly monotonically increasing.
     */
    convenience init(managedObject: MeasurementMO) throws {
        let accelerationFile = SensorValueFile(measurement: managedObject, fileType: .accelerationValueType)
        let directionFile = SensorValueFile(measurement: managedObject, fileType: .directionValueType)
        let rotationFile = SensorValueFile(measurement: managedObject, fileType: .rotationValueType)

        self.init(
            identifier: UInt64(managedObject.identifier),
            synchronizable: managedObject.synchronizable,
            synchronized: managedObject.synchronized,
            time: managedObject.time!,
            accelerationData: try accelerationFile.data(),
            rotationData: try rotationFile.data(),
            directionData: try directionFile.data()
        )

        if let eventMOs = managedObject.events?.array as? [EventMO] {

            for eventMO in eventMOs {
                let event = Event(managedObject: eventMO)
                events.append(event)
            }
        }

        if let trackMOs = managedObject.tracks?.array as? [TrackMO] {
            for trackMO in trackMOs {
                let track = try Track(managedObject: trackMO)
                tracks.append(track)
            }
        }

    }

    /**
     Initialize a `Measurement` by setting all properties.

     This results in a `Measurement` with a `nil` objectId.

     - Parameters:
        - identifier: A device wide unique identifier for this measurement. Usually set by incrementing a counter.
        - synchronizable: A flag, marking this `Measurement` as either ready for data syncrhonization or not.
        - synchronized: A flag, marking this `Measurement` as either synchronized or not.
        - time: The time this measurement was captured.
        - events: The user events that occurred during this `Measurement`.
        - tracks: The tracks containing all the data this `Measurement` has captured.
     */
    public init(
        identifier: UInt64,
        synchronizable: Bool = false,
        synchronized: Bool = false,
        time: Date = Date(),
        events: [Event] = [Event](),
        tracks: [Track] = [Track](),
        accelerationData: Data = Data(),
        rotationData: Data = Data(),
        directionData: Data = Data()
    ) {
        self.identifier = identifier
        self.synchronizable = synchronizable
        self.synchronized = synchronized
        self.time = time
        self.events = events
        self.tracks = tracks
        self.accelerationDate = accelerationData
        self.rotationData = rotationData
        self.directionData = directionData
    }

    /**
     Add a `Track` to the end of this `Measurement`.

     - Parameter track: The `Track` to add.
     */
    /*func append(track: Track) {
        tracks.append(track)
    }*/

    /**
     Add an `Event` to the list of events captured during this `Measurement`.

     - Parameter event: The `Event` to add to the `Measurement`.
     */
    /*func append(event: Event) {
        events.append(event)
    }*/

    /// Required by the `Hashable` protocol to produce a hash for this object.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    /// Required by the `Equatable` protocol to compare two `Measurement` instances.
    public static func == (lhs: FinishedMeasurement, rhs: FinishedMeasurement) -> Bool {
        return lhs.identifier == rhs.identifier
    }

    // TODO: Remove everything below?
    /// Provide the average speed of this measurement in m/s.
    //public func averageSpeed() -> Double {
        /*var sum = 0.0
        var counter = 0
        tracks.forEach { track in
            track.locations.forEach { location in
                if location.isValid {
                    sum += location.speed
                    counter += 1
                }
            }
        }

        if counter==0 {*/
            //return 0.0
        /*} else {
            return sum/Double(counter)
        }*/
    //}

    /// Provide the total duration of this measurement.
    /*public func totalDuration() -> TimeInterval {
        var totalTime = TimeInterval()
        tracks.forEach { track in
            guard let firstTime = track.locations.first?.time, let lastTime = track.locations.last?.time else {
                return
            }

            totalTime += lastTime.timeIntervalSince(firstTime)

        }

        return totalTime
    }*/

    /// Calculate the accumulated height value for this measurement.
    /*public func summedHeight() -> Double {
        var sum = 0.0
        tracks.forEach { track in

            if track.altitudes.isEmpty {
                os_log("Using location values to calculate accumulated height.", log: OSLog.measurement, type: .debug)
                var previousAltitude = 0.0
                var isFirst = true
                track.locations.forEach { location in
                    if isFirst {
                        previousAltitude = location.altitude
                        isFirst = false
                    } else if !(location.verticalAccuracy > FinishedMeasurement.verticalAccuracyThresholdMeters) {

                        let currentAltitude = location.altitude
                        let altitudeChange = currentAltitude - previousAltitude

                        if abs(altitudeChange) > FinishedMeasurement.ascendThresholdMeters {
                            if altitudeChange > 0.0 {
                                sum += altitudeChange
                            }
                            previousAltitude = location.altitude
                        }
                    }
                }
            } else {
                os_log("Using altimeter values to calculate accumulated height.", log: OSLog.measurement, type: .debug)
                var previousAltitude: Double? = nil
                for altitude in track.altitudes {
                    if let previousAltitude = previousAltitude {
                        let relativeAltitudeChange = altitude.relativeAltitude - previousAltitude
                        if relativeAltitudeChange > 0.1 {
                            sum += relativeAltitudeChange
                        }
                    }
                    previousAltitude = altitude.relativeAltitude
                }
            }
        }
        return sum
    }*/
}
