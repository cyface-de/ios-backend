/*
 * Copyright 2019 Cyface GmbH
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
import CoreLocation

/**
 This policy describes how to convert measurements between databases of version 3 and 4 of the Cyface model.
 It is used by a Mapping to carry out that conversion on devices installing an SDK requiring version 4 but having version 3.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 4.0.0
 */
class MeasurementToMeasurementPolicy: NSEntityMigrationPolicy {

    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        try super.createDestinationInstances(forSource: sInstance, in: mapping, manager: manager)

        guard let measurement = manager.destinationInstances(forEntityMappingName: mapping.name, sourceInstances: [sInstance]).first else {
            fatalError("No Measurement.")
        }

        // Create one track per measurement
        let track = NSEntityDescription.insertNewObject(forEntityName: "Track", into: measurement.managedObjectContext!)

        track.setValue(measurement, forKey: "measurement")

        // Load the geo locations
        guard let locations = sInstance.value(forKey: "geoLocations") as? NSOrderedSet else {
            fatalError()
        }

        // Calculate the track length for the new measurement
        let trackLength = calcLength(ofLocations: locations)
        measurement.setPrimitiveValue(trackLength, forKey: "trackLength")

        // Add geo locations to user info so we can later associate them with the correct thread
        let migratedLocations = migrate(locations: locations, forTrack: track)
        track.setValue(migratedLocations, forKey: "locations")
    }

    override func createRelationships(forDestination dInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        try super.createRelationships(forDestination: dInstance, in: mapping, manager: manager)

        // Get the one and only track for the migrated measurement and insert it into the measurement
        let trackFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Track")
        let trackFetchRequestPredicate = NSPredicate(format: "measurement == %@", dInstance)
        trackFetchRequest.predicate = trackFetchRequestPredicate
        guard let tracks = try dInstance.managedObjectContext?.fetch(trackFetchRequest) else {
            fatalError()
        }

        dInstance.setValue(NSOrderedSet(array: tracks), forKey: "tracks")
    }

    /**
     Calculate the length of a version 3 array of geo locations from a measurement. This is required to update the migrated measurement with the track length.

     - Parameters:
        - ofLocations: The locations to use for track length calculation.
     */
    func calcLength(ofLocations locations: NSOrderedSet) -> NSNumber {
        var trackLength = 0.0
        var lastLocation: CLLocation?
        for location in locations {
            guard let location = location as? NSManagedObject else {
                fatalError("Unable to convert geo locations!")
            }

            guard let lat = location.primitiveValue(forKey: "lat") as? Double,
                let lon = location.primitiveValue(forKey: "lon") as? Double else {
                    fatalError("Unable to convert data from geo locations!")
            }

            let geoLocation = CLLocation(latitude: lat, longitude: lon)
            if let lastLocation = lastLocation {
                trackLength += geoLocation.distance(from: lastLocation)
            }
            lastLocation = geoLocation
        }
        return NSNumber(value: trackLength)
    }

    /**
     Migrates all version 3 locations to version 4 locations as children of the provided track.

     - Parameters:
        - locations: The version 3 locations to migrate to version 4
        - forTrack: The track to store the migrated version 4 locations to.
     */
    func migrate(locations: NSOrderedSet, forTrack track: NSManagedObject) -> NSOrderedSet {
        var migratedLocations = [NSManagedObject]()
        for originalLocation in locations {
            let migratedLocation = NSEntityDescription.insertNewObject(forEntityName: "GeoLocation", into: track.managedObjectContext!)
            guard let originalLocation = originalLocation as? NSManagedObject else {
                fatalError()
            }

            guard let lat = originalLocation.primitiveValue(forKey: "lat") as? Double,
                let lon = originalLocation.primitiveValue(forKey: "lon") as? Double,
                let speed = originalLocation.primitiveValue(forKey: "speed") as? Double,
                let accuracy = originalLocation.primitiveValue(forKey: "accuracy") as? Double,
                let timestamp = originalLocation.primitiveValue(forKey: "timestamp") as? Int64
                else {
                    fatalError("Unable to convert data from geo locations!")
            }
            migratedLocation.setPrimitiveValue(lat, forKey: "lat")
            migratedLocation.setPrimitiveValue(lon, forKey: "lon")
            migratedLocation.setPrimitiveValue(speed, forKey: "speed")
            migratedLocation.setPrimitiveValue(accuracy, forKey: "accuracy")
            migratedLocation.setPrimitiveValue(timestamp, forKey: "timestamp")
            migratedLocation.setValue(track, forKey: "track")
            migratedLocations.append(migratedLocation)
        }
        return NSOrderedSet(array: migratedLocations)
    }

    /**
     Reads geo locations from a version 3 measurement and inserts them into a version 4 track entity.

     - Parameters:
        - from: The measurement model object version 3 to load the geo locations from.
        - into: The track to insert the locations into
        - withDestination: The destination `NSManagedObjectContext` to use to create copied geo locations from.
     */
    func insertLocations(from source: NSManagedObject, into track: NSManagedObject, withDestination context: NSManagedObjectContext) {
        var migratedLocations = [NSManagedObject]()
        guard let originalLocations = source.value(forKey: "geoLocations") as? NSOrderedSet else {
            fatalError()
        }

        for originalLocation in originalLocations {
            let migratedLocation = NSEntityDescription.insertNewObject(forEntityName: "GeoLocation", into: context)
            guard let originalLocation = originalLocation as? NSManagedObject else {
                fatalError()
            }

            guard let lat = originalLocation.primitiveValue(forKey: "lat") as? Double,
                let lon = originalLocation.primitiveValue(forKey: "lon") as? Double,
                let speed = originalLocation.primitiveValue(forKey: "speed") as? Double,
                let accuracy = originalLocation.primitiveValue(forKey: "accuracy") as? Double,
                let timestamp = originalLocation.primitiveValue(forKey: "timestamp") as? Int64
                else {
                    fatalError("Unable to convert data from geo locations!")
            }
            migratedLocation.setPrimitiveValue(lat, forKey: "lat")
            migratedLocation.setPrimitiveValue(lon, forKey: "lon")
            migratedLocation.setPrimitiveValue(speed, forKey: "speed")
            migratedLocation.setPrimitiveValue(accuracy, forKey: "accuracy")
            migratedLocation.setPrimitiveValue(timestamp, forKey: "timestamp")
            migratedLocation.setValue(track, forKey: "track")
            migratedLocations.append(migratedLocation)
        }
        track.setValue(NSOrderedSet(array: migratedLocations), forKey: "locations")
    }
}
