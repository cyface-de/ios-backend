/*
 * Copyright 2022-2024 Cyface GmbH
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

import CoreData
import OSLog

/**
 Instances of this class represent a single data capturing session, framed by calls to `DataCapturingService.start` and `DataCapturingService.stop`.

 Initially this is not going to be saved via CoreData. As soon as you call an appropriate save method on the `PersistenceLayer` the object is stored to CoreData and this objects `objectId` will receive a value.

 A `Measurement` can be synchronized to a Cyface server via an instance of `Synchronizer`.

 - Author: Klemens Muthmann
 - Version: 2.0.0
 - since: 11.0.0
 */
public class FinishedMeasurement: Hashable, Equatable {
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
    public let accelerationData: Data
    public let rotationData: Data
    public let directionData: Data

    /**
     Initialize a new `Measurement` from an existing CoreData managed object.

     After calling this initializer, this objects `objectId` is going to be set to the managed objects `objectId`.

     - parameter managedObject: The managed CoreData object to initialize this `Measurement` from.
     - throws: `InconstantData.locationOrderViolation` if the timestamps of the locations in this measurement are not strongly monotonically increasing.
     */
    convenience init(managedObject: MeasurementMO) throws {
        let accelerationFile = SensorValueFile(fileType: .accelerationValueType, qualifier: String(managedObject.unsignedIdentifier))
        let directionFile = SensorValueFile(fileType: .directionValueType, qualifier: String(managedObject.unsignedIdentifier))
        let rotationFile = SensorValueFile(fileType: .rotationValueType, qualifier: String(managedObject.unsignedIdentifier))

        self.init(
            identifier: managedObject.unsignedIdentifier,
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
        - accelerationData: The raw captured acceleration data in an appropriate binary format.
        - rotationData: The raw captured rotation data in an appropriate binary format.
        - directionData: The raw captured directional data in an appropriate binary format.
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
        self.accelerationData = accelerationData
        self.rotationData = rotationData
        self.directionData = directionData
    }

    /// Required by the `Hashable` protocol to produce a hash for this object.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    /// Required by the `Equatable` protocol to compare two `Measurement` instances.
    public static func == (lhs: FinishedMeasurement, rhs: FinishedMeasurement) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}
