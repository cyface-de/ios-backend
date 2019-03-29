//
//  GeoLocationToTrackPolicy.swift
//  DataCapturing
//
//  Created by Team Cyface on 18.03.19.
//  Copyright © 2019 Cyface GmbH. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation

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
        /*var userInfo = manager.userInfo == nil ? [AnyHashable: Any]() : manager.userInfo!*/
        let migratedLocations = migrate(locations: locations, forTrack: track)
        /*userInfo[track.objectID]=migratedLocations
        manager.userInfo = userInfo*/
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

        // Get the locations from user info and add them to the track
        /*guard let userInfo = manager.userInfo else {
            fatalError()
        }

        guard let track = tracks.first as? NSManagedObject else {
            fatalError()
        }

        let locations = userInfo[track.objectID]
        track.setValue(locations, forKey: "locations")*/
    }

    func calcLength(ofLocations locations: NSOrderedSet) -> NSNumber {
        var trackLength = 0.0
        let distanceCalculationStrategy = DefaultDistanceCalculationStrategy()
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
                trackLength += distanceCalculationStrategy.calculateDistance(from: geoLocation, to: lastLocation)
            }
            lastLocation = geoLocation
        }
        return NSNumber(value: trackLength)
    }

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
