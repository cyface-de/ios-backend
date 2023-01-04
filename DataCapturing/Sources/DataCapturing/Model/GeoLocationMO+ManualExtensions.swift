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
        location.objectId = self.objectID
        try update(from: location)
    }

    /// Update this managed object with the values from the provided `GeoLocation`.
    func update(from location: GeoLocation) throws {
        guard location.objectId == self.objectID else {
            throw PersistenceError.inconsistentState
        }

        guard let parentObjectId = location.track.objectId else {
            throw PersistenceError.inconsistentState
        }

        self.lat = location.latitude
        self.lon = location.longitude
        self.accuracy = location.accuracy
        guard let managedParent = try managedObjectContext?.existingObject(with: parentObjectId) as? TrackMO else {
            throw PersistenceError.inconsistentState
        }
        self.track = managedParent
        self.isPartOfCleanedTrack = location.isValid
        self.speed = location.speed
        self.timestamp = Int64(location.timestamp)
    }

}
