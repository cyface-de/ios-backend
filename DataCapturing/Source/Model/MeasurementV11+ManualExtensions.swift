//
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

import CoreData

extension MeasurementV11 {

    /// Load the V11 measurement corresponding to the provided one from the database. If there is no such measurement a ``PersistenceError`` will be thrown.
    static func load(measurement: Measurement, context: NSManagedObjectContext) throws -> MeasurementV11 {
        let measurementFetchRequest = MeasurementV11.fetchRequest()
        measurementFetchRequest.predicate = NSPredicate(format: "identifier = %i", measurement.identifier)
        let fetchedMeasurements = try context.fetch(measurementFetchRequest)

        guard fetchedMeasurements.count == 1 else {
            throw PersistenceError.measurementNotLoadable(measurement.identifier)
        }

        return fetchedMeasurements[0]
    }

    /// The last track from this measurement.
    func lastTrack() -> TrackV11 {
        guard let v11Track = tracks?.lastObject as? TrackV11 else {
            fatalError("Wrong class stored to tracks relationship. Unable to cast to TrackV11")
        }

        return v11Track
    }

    /// The tracks from this measurement already cast to the correct type.
    func typedTracks() -> [TrackV11] {
        guard let dbTracks = tracks?.array as? [TrackV11] else {
            fatalError("Unable to load MeasurementV11 tracks.")
        }
        return dbTracks
    }
}
