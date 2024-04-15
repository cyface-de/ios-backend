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

import Foundation
import CoreData

/**
Represents a single continuously measured track of geo location and associated sensor data.

 Each track is part of a parent `Measurement`. New Tracks are appended to a measurement if the user pauses and resumes capturing of that  `Measurement`.

 - Author: Klemens Muthmann
 - Version: 2.0.0
 - since: 11.0.0
 */
public class Track {
    /// The locations constituting this track.
    public var locations: [GeoLocation]
    /// The barometric altitudes captured for this track. If the device does not support an altimeter, this array is empty.
    public var altitudes: [Altitude]

    /**
     A copy initializer creating a new `Track` based of the values of a CoreData managed object.

     Calling this initializer causes the new `Track` to use the managed objects `objectID`.

     - Parameters:
        - managedObject: The CoreData object to initialize all the properties of the new `Track` from.
     - throws: `InconsistentData.locationOrderViolation` if the order of the locations in the `managedObject` is not strongly monotonically increasing.
     */
    public convenience init(managedObject: TrackMO) throws {
        self.init()

        var locations = [GeoLocation]()
        for geoLocationMO in managedObject.typedLocations() {
            locations.append(GeoLocation(managedObject: geoLocationMO))
        }
        self.locations = locations

        var altitudes = [Altitude]()
        for altitude in managedObject.typedAltitudes() {
            altitudes.append(Altitude(managedObject: altitude))
        }
        self.altitudes = altitudes
    }

    /**
     An initializer for a new empty `Track`.

     - Parameter parent: The parent `Measurement` of this new `Track`.
     */
    init() {
        self.locations = [GeoLocation]()
        self.altitudes = [Altitude]()
    }
}
