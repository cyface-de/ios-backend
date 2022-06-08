//
//  GeoLocationMO+ManualExtensions.swift
//  DataCapturing
//
//  Created by Klemens Muthmann on 13.04.22.
//

import Foundation
import CoreData

extension GeoLocationMO {
    convenience init(location: inout GeoLocation, context: NSManagedObjectContext) throws {
        self.init(context: context)
        location.objectId = self.objectID
        try update(from: location)
    }

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
