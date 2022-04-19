//
//  Track.swift
//  DataCapturing
//
//  Created by Klemens Muthmann on 13.04.22.
//

import Foundation
import CoreData

public struct Track {
    var objectId: NSManagedObjectID?
    public var locations: [GeoLocation]
    let measurement: Measurement

    init(managedObject: TrackMO, parent: Measurement) throws {
        self.init(parent: parent)
        self.objectId = managedObject.objectID

        if let geoLocationMOs = managedObject.locations?.array as? [GeoLocationMO] {
            for geoLocationMO in geoLocationMOs {
                _ = try GeoLocation(managedObject: geoLocationMO, parent: &self)
            }
        }
    }

    init(locations: [GeoLocation] = [GeoLocation](), parent: Measurement) {
        self.locations = locations
        self.measurement = parent
    }

    mutating func append(location: GeoLocation) throws {
        guard (locations.last?.timestamp ?? 0) < location.timestamp else {
            throw InconsistentData.locationOrderViolated
        }

        self.locations.append(location)
    }
}
