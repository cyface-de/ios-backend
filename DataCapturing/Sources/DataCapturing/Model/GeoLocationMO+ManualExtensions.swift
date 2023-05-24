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
 The class extended here is generated during the build process, by CoreData from the data model file.
 */
extension GeoLocationMO {
    /// Initializes a managed object from an existing `GeoLocation`.
    convenience init(location: inout GeoLocation, context: NSManagedObjectContext) throws {
        self.init(context: context)
        try update(from: location)
    }

    /// Update this managed object with the values from the provided `GeoLocation`.
    func update(from location: GeoLocation) throws {
        self.lat = location.latitude
        self.lon = location.longitude
        self.accuracy = location.accuracy
        self.speed = location.speed
        self.time = location.time
        self.verticalAccuracy = location.verticalAccuracy
        self.altitude = location.altitude
    }

}
