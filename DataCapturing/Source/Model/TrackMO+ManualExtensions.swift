/*
 * Copyright 2017-2022 Cyface GmbH
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

extension TrackMO {
    /// Initialize a CoreData managed track object from the properties of a `Track`.
    convenience init(track: inout Track, context: NSManagedObjectContext) throws {
        self.init(context: context)
        track.objectId = self.objectID

        try update(from: track)
    }

    /// Refresh the properties of this managed object from the provided `Track`.
    func update(from track: Track) throws {
        for i in 0..<track.locations.count {
            var location = track.locations[i]

            guard let context = managedObjectContext else {
                fatalError()
            }

            if let locationObjectId = location.objectId {
                guard let managedLocation = try context.existingObject(with: locationObjectId) as? GeoLocationMO else {
                    throw PersistenceError.inconsistentState
                }
                try managedLocation.update(from: location)
            } else {
                insertIntoLocations(try GeoLocationMO(location: &location, context: context), at: i)
            }
        }

        // TODO: Delete invalid locations from managed location. This should not happen in our current use cases but would still be necessary conceptually.
    }
}
