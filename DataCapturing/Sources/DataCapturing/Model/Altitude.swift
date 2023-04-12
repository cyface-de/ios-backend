/*
 * Copyright 2023 Cyface GmbH
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
 A struct to wrap all the information associated with a measured altitude provided by an altimeter.

 - Author: Klemens Muthmann
 */
public class Altitude: CustomStringConvertible {
    /// The database identifier used by CoreData to identify this object in the database.
    var objectId: NSManagedObjectID?
    /// The relative altitude change since the last measured value, in meters.
    let relativeAltitude: Double
    /// The currently measured pressure in kilopascals .
    let pressure: Double
    /// The time this was measured.
    let time: Date
    /// Description to display this object as
    public var description: String {
        return "Altitude (relativeAltitude: \(relativeAltitude), pressure: \(pressure), timestamp: \(time.debugDescription))"
    }

    convenience init(managedObject: AltitudeMO) {
        self.init(relativeAltitude: managedObject.altitude, time: managedObject.time!)
    }

    init(relativeAltitude: Double, pressure: Double = 0.0, time: Date) {
        self.relativeAltitude = relativeAltitude
        self.pressure = pressure
        self.time = time
    }
}
