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

// TODO: There probably need to be two kinds of Measurement instances (and other objects in that hierarchy). One is used to create new instances and one is used for already synchronized ones. The reason is, that refreshing the objectId via the context does not work, as the context changes the objectId as soon as a call to context.save() happens. -.-
/**
Instances of this class represent a single data capturing session, framed by calls to `DataCapturingService.start` and `DataCapturingService.stop`.

 Initially this is not going to be saved via CoreData. As soon as you call an appropriate save method on the `PersistenceLayer` the object is stored to CoreData and this objects `objectId` will receive a value.

 A `Measurement` can be synchronized to a Cyface server via an instance of `Synchronizer`.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - since: 11.0.0
 */
public class Measurement: Hashable, Equatable {
    /// This measurements CoreData identifier or `nil` if the object has not been saved yet.
    var objectId: NSManagedObjectID?
    /// The number of accelerations stored by this measurement. This information is required to deserialize the binary format for those values.
    public var accelerationsCount: Int32
    /// The number of rotations stored by this measurement. This information is required to deserialize the binary format for those values.
    public var rotationsCount: Int32
    /// The number of directions stored by this measurement. This information is required to deserialize the binary format for those values.
    public var directionsCount: Int32
    /// A device wide unique identifier for this measurement. Usually set by incrementing a counter.
    public let identifier: Int64
    /// A flag, marking this `Measurement` as either ready for data syncrhonization or not.
    public var synchronizable: Bool
    /// A flag, marking this `Measurement` as either synchronized or not.
    public var synchronized: Bool
    /// The UNIX timestamp in milliseconds since the 1st of January 1970, when this measurement was started.
    public let timestamp: Int64
    /// The calculated length of the `Measurement`. See `DistanceCalculationStrategy` for further details.
    public var trackLength: Double
    /// The user events that occurred during this `Measurement`.
    public var events: [Event]
    /// The tracks containing all the data this `Measurement` has captured.
    public var tracks: [Track]

    /**
     Initialize a new `Measurement` from an existing CoreData managed object.

     After calling this initializer, this objects `objectId` is going to be set to the managed objects `objectId`.

     - parameter managedObject: The managed CoreData object to initialize this `Measurement` from.
     - throws: `InconstantData.locationOrderViolation` if the timestamps of the locations in this measurement are not strongly monotonically increasing.
     */
    convenience init(managedObject: MeasurementMO) throws {
        self.init(
            identifier: managedObject.identifier,
            synchronizable: managedObject.synchronizable,
            synchronized: managedObject.synchronized,
            accelerationsCount: managedObject.accelerationsCount,
            rotationsCount: managedObject.rotationsCount,
            directionsCount: managedObject.directionsCount,
            timestamp: managedObject.timestamp,
            trackLength: managedObject.trackLength)
        self.objectId = managedObject.objectID

        if let eventMOs = managedObject.events?.array as? [EventMO] {

            for eventMO in eventMOs {
                let event = Event(managedObject: eventMO, parent: self)
                events.append(event)
            }
        }

        if let trackMOs = managedObject.tracks?.array as? [TrackMO] {
            for trackMO in trackMOs {
                let track = try Track(managedObject: trackMO, parent: self)
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
        -  synchronized: A flag, marking this `Measurement` as either synchronized or not.
        - accelerationsCount: The number of accelerations stored by this measurement. This information is required to deserialize the binary format for those values.
        - rotationsCount: The number of rotations stored by this measurement. This information is required to deserialize the binary format for those values.
        - directionsCount: The number of directions stored by this measurement. This information is required to deserialize the binary format for those values.
        - timestamp: The UNIX timestamp in milliseconds since the 1st of January 1970, when this measurement was started.
        - trackLength: The calculated length of the `Measurement`. See `DistanceCalculationStrategy` for further details.
        - events: The user events that occurred during this `Measurement`.
        - tracks: The tracks containing all the data this `Measurement` has captured.
     */
    init(identifier: Int64, synchronizable: Bool = false, synchronized: Bool = false, accelerationsCount: Int32 = 0, rotationsCount: Int32 = 0, directionsCount: Int32 = 0, timestamp: Int64 = DataCapturingService.currentTimeInMillisSince1970(), trackLength: Double = 0.0, events: [Event] = [Event](), tracks: [Track] = [Track]()) {
        self.identifier = identifier
        self.synchronizable = synchronizable
        self.synchronized = synchronized
        self.accelerationsCount = accelerationsCount
        self.rotationsCount = rotationsCount
        self.directionsCount = directionsCount
        self.timestamp = timestamp
        self.trackLength = trackLength
        self.events = events
        self.tracks = tracks
    }

    /**
     Add a `Track` to the end of this `Measurement`.

     - Parameter track: The `Track` to add.
     */
    func append(track: Track) {
        tracks.append(track)
    }

    /**
     Add an `Event` to the list of events captured during this `Measurement`.

     - Parameter event: The `Event` to add to the `Measurement`.
     */
    func append(event: Event) {
        events.append(event)
    }

    /// Required by the `Hashable` protocol to produce a hash for this object.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    /// Required by the `Equatable` protocol to compare two `Measurement` instances.
    public static func ==(lhs: Measurement, rhs: Measurement) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}
