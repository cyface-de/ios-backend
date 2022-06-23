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

/**
Represents a single continuously measured track of geo location and associated sensor data.

 Each track is part of a parent `Measurement`. New Tracks are appended to a measurement if the user pauses and resumes capturing of that  `Measurement`.

 - Author: Klemens Muthmann
 - Version: 1.1.0
 - since: 11.0.0
 */
public class Track {
    /// The database identifier used by CoreData to identify this object in the database.
    var objectId: NSManagedObjectID?
    /// The locations constituting this track.
    public var locations: [GeoLocation]
    /// The measurement this track belongs to.
    let measurement: Measurement

    /**
     A copy initializer creating a new `Track` based of the values of a CoreData managed object.

     Calling this initializer causes the new `Track` to use the managed objects `objectID`.

     - Parameters:
        - managedObject: The CoreData object to initialize all the properties of the new `Track` from.
        - parent: The parent `Measurement` of the track.
     - throws: `InconsistentData.locationOrderViolation` if the order of the locations in the `managedObject` is not strongly monotonically increasing.
     */
    convenience init(managedObject: TrackMO, parent: Measurement) throws {
        self.init(parent: parent)
        self.objectId = managedObject.objectID

        if let geoLocationMOs = managedObject.locations?.array as? [GeoLocationMO] {
            for geoLocationMO in geoLocationMOs {
                try append(location: GeoLocation(managedObject: geoLocationMO, parent: self))
            }
        }
    }

    /**
     An initializer for a new empty `Track`.

     Initially this `Track` is not stored via CoreData and thus its objectId is going to be `nil`. The `objectId` will be updated as sson as the parent `Measurement` is saved via CoreData.

     - Parameter parent: The parent `Measurement` of this new `Track`.
     */
    init(parent: Measurement) {
        self.locations = [GeoLocation]()
        self.measurement = parent
    }

    /**
     Append a `GeoLocation` to the end of this `Track`.

     The appended location must have this `Track` as its parent.

     - Parameter location: The location to append.
     - Throws InconsistentData.locationOrderViolated: If the newly added locations timestamp is smaller then the one from the previous location.
     */
    func append(location: GeoLocation) throws {
        // We can not check this, since there are old installations where this is not true.
        /*guard (locations.last?.timestamp ?? 0) < location.timestamp else {
            throw InconsistentData.locationOrderViolated
        }*/

        self.locations.append(location)
    }
}
