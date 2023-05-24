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
        try update(from: track)
    }

    // TODO: All these update methods should not be necessary anymore.
    /// Refresh the properties of this managed object from the provided `Track`.
    func update(from track: Track) throws {
        //try updateLocations(from: track)

        //try updateAltitudes(from: track)

        // TODO: Delete invalid locations from managed location. This should not happen in our current use cases but would still be necessary conceptually.
    }

    /**
     The altitudes in this measurement already cast to the correct type.
     */
    public func typedAltitudes() -> [AltitudeMO] {
        guard let typedAltitudes = altitudes?.array as? [AltitudeMO] else {
            fatalError("Unable to cast altitudes to the correct type!")
        }

        return typedAltitudes
    }

    /**
     The locations from this measurement already cast to the correct type.
     */
    public func typedLocations() -> [GeoLocationMO] {
        guard let typedLocations = locations?.array as? [GeoLocationMO] else {
            fatalError("Unable to cast altitudes to the correct type!")
        }

        return typedLocations
    }

    /*private func updateLocations(from track: Track) throws {
        for i in 0..<track.locations.count {
            var location = track.locations[i]

            guard let context = managedObjectContext else {
                fatalError()
            }

            /*guard let managedLocation = try context.existingObject(with: locationObjectId) as? GeoLocationMO else {
                throw PersistenceError.inconsistentState
            }
            try managedLocation.update(from: location)*/
        }
    }

    private func updateAltitudes(from track: Track) throws {
        try track.altitudes.enumerated().forEach { (index, value) in
            var altitude = value
            guard let context = managedObjectContext else {
                fatalError()
            }

            if let altitudeObjectId = altitude.objectId {
                guard let managedAltitude = try context.existingObject(with: altitudeObjectId) as? AltitudeMO else {
                    throw PersistenceError.inconsistentState
                }
                try managedAltitude.update(from: altitude)
            } else {
                insertIntoAltitudes(try AltitudeMO(altitude: &altitude, context: context), at: index)
            }
        }
    }*/
}
