//
//  GeoLocationMO+ManualExtensions.swift
//  DataCapturing
//
//  Created by Klemens Muthmann on 13.04.22.
//

import Foundation
import CoreData

extension GeoLocationMO {
    convenience init(location: GeoLocation, parent: TrackMO, context: NSManagedObjectContext) {
        self.init(context: context)
        self.lat = location.latitude
        self.lon = location.longitude
        self.speed = location.speed
        self.timestamp = location.timestamp
        self.accuracy = location.accuracy
        self.isPartOfCleanedTrack = location.isValid
        parent.addToLocations(self)
        self.track = parent
    }

}
