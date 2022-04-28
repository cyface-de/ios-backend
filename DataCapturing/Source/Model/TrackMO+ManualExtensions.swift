//
//  TrackMO+ManualExtensions.swift
//  DataCapturing
//
//  Created by Klemens Muthmann on 27.04.22.
//

import Foundation
import CoreData

extension TrackMO {
    convenience init(track: inout Track, context: NSManagedObjectContext) throws {
        self.init(context: context)
        track.objectId = self.objectID

        try update(from: track)
    }

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
