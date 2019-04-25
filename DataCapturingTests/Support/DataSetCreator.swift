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
@testable import DataCapturing

/**
 This class contains utility code used to create data stores in specific versions of the Cyface model.

 - Author: Klemens Muthmann
 - Version: 1.2.0
 - Since: 4.0.0
 */
class DataSetCreator {
    /**
     Create a version 1 data set with two measurements 1 and 2 and 1.000 and 2.000 geo locations at timestamps 10.000 and 20.000.

     - Parameter in: The container to create the data in
     */
    static func createV1Data(in container: NSPersistentContainer) throws {
        let context = container.newBackgroundContext()
        _ = createV1Measurement(withIdentifier: 1, atTime: 10_000, containingCountOfGeoLocations: 1_000, inContext: context)
        _ = createV1Measurement(withIdentifier: 2, atTime: 20_000, containingCountOfGeoLocations: 2_000, inContext: context)
        try context.save()
    }

    /**
     Creates a version two measurement in the provided version 1 `NSManagedObjectContext`.

     - Parameters:
        - withIdentifier: The identifier of the new measurement
        - atTime: The timestamp in milliseconds since the first of january 1970 the measurement was created on
        - containingCountOfGeoLocations: The amount of geo locations to create for the new measurement
        - inContext: The *CoreData* `NSManagedObjectContext` to create the data in
     - Returns: The newly created measurement as an `NSManagedObject`
     */
    static func createV1Measurement(withIdentifier identifier: Int, atTime time: Int64, containingCountOfGeoLocations countOfGeoLocations: Int, inContext context: NSManagedObjectContext) -> NSManagedObject {
        let measurement = NSEntityDescription.insertNewObject(forEntityName: "Measurement", into: context)
        measurement.setPrimitiveValue(identifier, forKey: "identifier")
        measurement.setPrimitiveValue(false, forKey: "synchronized")
        measurement.setPrimitiveValue(time, forKey: "timestamp")

        var accelerations01 = [NSManagedObject]()
        var geoLocations01 = [NSManagedObject]()
        for i in 0..<countOfGeoLocations*10 {
            if i % 10 == 0 {
                let geoLocation = NSEntityDescription.insertNewObject(forEntityName: "GeoLocation", into: context)
                geoLocation.setPrimitiveValue(1.0, forKey: "accuracy")
                geoLocation.setPrimitiveValue(time + Int64(i * 100), forKey: "timestamp") // add 1000 milliseconds to timestamp
                geoLocation.setPrimitiveValue(51.0+Double(i)/1_000, forKey: "lat")
                geoLocation.setPrimitiveValue(13.0+Double(i)/1_000, forKey: "lon")
                geoLocation.setPrimitiveValue(1.0, forKey: "speed")
                geoLocations01.append(geoLocation)
            }

            let acceleration = NSEntityDescription.insertNewObject(forEntityName: "Acceleration", into: context)
            acceleration.setPrimitiveValue(time + Int64(i * 100), forKey: "timestamp")
            acceleration.setPrimitiveValue(1.0, forKey: "ax")
            acceleration.setPrimitiveValue(1.0, forKey: "ay")
            acceleration.setPrimitiveValue(1.0, forKey: "az")
            accelerations01.append(acceleration)
        }

        measurement.setValue(NSOrderedSet(array: geoLocations01), forKey: "geoLocations")
        measurement.setValue(NSOrderedSet(array: accelerations01), forKey: "accelerations")

        return measurement
    }

    /**
     Create a version 2 data set with two measurements 1 and 2 and 1.000 and 2.000 geo locations at timestamps 10.000 and 20.000.

     - Parameter in: The container to create the data in
     */
    static func createV2Data(in container: NSPersistentContainer) throws {
        let context = container.newBackgroundContext()
        createV2Measurement(withIdentifier: 1, atTime: 10_000, containingCountOfGeoLocations: 1_000, inContext: context)
        createV2Measurement(withIdentifier: 2, atTime: 20_000, containingCountOfGeoLocations: 2_000, inContext: context)
        try context.save()
    }

    /**
     Creates a version two measurement in the provided version 2 `NSManagedObjectContext`.

     - Parameters:
        - withIdentifier: The identifier of the new measurement
        - atTime: The timestamp in milliseconds since the first of january 1970 the measurement was created on
        - containingCountOfGeoLocations: The amount of geo locations to create for the new measurement
        - inContext: The *CoreData* `NSManagedObjectContext` to create the data in
     */
    static func createV2Measurement(withIdentifier identifier: Int, atTime time: Int64, containingCountOfGeoLocations countOfGeoLocations: Int, inContext context: NSManagedObjectContext) {
        let measurement = createV1Measurement(withIdentifier: identifier, atTime: time, containingCountOfGeoLocations: countOfGeoLocations, inContext: context)
        measurement.setValue("BICYCLE", forKey: "context")
    }

    /**
     Create a version 3 data set with two measurements 1 and 2 and 200 and 300 geo locations at timestamps 10.000 and 20.000.

     - Parameter in: The container to create the data in
     */
    static func createV3Data(in container: NSPersistentContainer) throws {
        let context = container.newBackgroundContext()
        let measurement01 = NSEntityDescription.insertNewObject(forEntityName: "Measurement", into: context)
        measurement01.setPrimitiveValue(200*100, forKey: "accelerationsCount")
        measurement01.setPrimitiveValue("BICYCLE", forKey: "context")
        measurement01.setPrimitiveValue(Int64(1), forKey: "identifier")
        measurement01.setPrimitiveValue(false, forKey: "synchronized")
        measurement01.setPrimitiveValue(Int64(10_000), forKey: "timestamp")

        var geoLocations = [NSManagedObject]()
        for i in 0...199 {
            let geoLocation = NSEntityDescription.insertNewObject(forEntityName: "GeoLocation", into: context)
            geoLocation.setPrimitiveValue(1.0, forKey: "accuracy")
            geoLocation.setPrimitiveValue(51.0+0.01*Double(i), forKey: "lat")
            geoLocation.setPrimitiveValue(13.7+0.01*Double(i), forKey: "lon")
            geoLocation.setPrimitiveValue(1.0, forKey: "speed")
            geoLocation.setPrimitiveValue(10_000 + i, forKey: "timestamp")
            geoLocations.append(geoLocation)
        }

        measurement01.setValue(NSOrderedSet(array: geoLocations), forKey: "geoLocations")

        let measurement02 = NSEntityDescription.insertNewObject(forEntityName: "Measurement", into: context)
        measurement02.setPrimitiveValue(300*100, forKey: "accelerationsCount")
        measurement02.setPrimitiveValue("BICYCLE", forKey: "context")
        measurement02.setPrimitiveValue(Int64(2), forKey: "identifier")
        measurement02.setPrimitiveValue(false, forKey: "synchronized")
        measurement02.setPrimitiveValue(Int64(20_000), forKey: "timestamp")

        var geoLocations02 = [NSManagedObject]()
        for i in 0...299 {
            let geoLocation = NSEntityDescription.insertNewObject(forEntityName: "GeoLocation", into: context)
            geoLocation.setPrimitiveValue(1.0, forKey: "accuracy")
            geoLocation.setPrimitiveValue(52.0+0.01*Double(i), forKey: "lat")
            geoLocation.setPrimitiveValue(13.7+0.01*Double(i), forKey: "lon")
            geoLocation.setPrimitiveValue(1.0, forKey: "speed")
            geoLocation.setPrimitiveValue(20_000+i, forKey: "timestamp")
            geoLocations02.append(geoLocation)
        }
        measurement02.setValue(NSOrderedSet(array: geoLocations02), forKey: "geoLocations")

        try context.save()
    }

    static func createV4Data(in container: NSPersistentContainer) throws {
        let context = container.newBackgroundContext()

        let measurement01 = createV4Measurement(450*100, "BICYCLE", Int64(1), false, Int64(10_000), 450.0, context)
        let trackOne = NSEntityDescription.insertNewObject(forEntityName: "Track", into: context)
        let trackOneGeoLocations = createV4GeoLocations(200, Int64(10_000), trackOne, context)
        trackOne.setValue(NSOrderedSet(array: trackOneGeoLocations), forKey: "locations")
        trackOne.setValue(measurement01, forKey: "measurement")
        let trackTwo = NSEntityDescription.insertNewObject(forEntityName: "Track", into: context)
        let trackTwoGeoLocations = createV4GeoLocations(250, 10_300, trackTwo, context)
        trackTwo.setValue(NSOrderedSet(array: trackTwoGeoLocations), forKey: "locations")
        trackTwo.setValue(measurement01, forKey: "measurement")

        let measurement02 = createV4Measurement(300*100, "BICYCLE", Int64(2), false, Int64(20_000), 300, context)
        let trackForMeasurementTwo = NSEntityDescription.insertNewObject(forEntityName: "Track", into: context)
        let trackForMeasurementTwoGeoLocations = createV4GeoLocations(300, Int64(20_000), trackForMeasurementTwo, context)
        trackForMeasurementTwo.setValue(NSOrderedSet(array: trackForMeasurementTwoGeoLocations), forKey: "locations")
        trackForMeasurementTwo.setValue(measurement02, forKey: "measurement")

        try context.save()
    }

    /**
     Creates a new measurement instance as an `NSManagedObject` in a Cyface version 4 database.

     - Parameters:
        - accelerationsCount: The number of accelerations stored with this measurement. Since accelerations are not stored in the database in version 4 anymore, these objects are not actually created.
        - vehicleContext: The vehicle used to capture the measurement. Usually one of "BICYCLE", "CAR" or "MOTORBIKE", but might be any `String` for simulation purposes.
        - identifier: The measurement identifier as a device wide unique identifier, used to distinguish this measurement from others.
        - synchronized: Whether this measurement is already synchronized to a server or not.
        - timestamp: The time the measurement was started in milliseconds since the 1st of january 1970.
        - trackLength: The length of the track in meters
        - context: An `NSManagedObjectContext` used to create the new `NSManagedObject` instance. This must be a version 4 `NSManagedObjectContext`.
     - Returns: A new version 4 measurement.
     */
    static func createV4Measurement(_ accelerationsCount: Int64, _ vehicleContext: String, _ identifier: Int64, _ synchronized: Bool, _ timestamp: Int64, _ trackLength: Double, _ context: NSManagedObjectContext) -> NSManagedObject {
        let ret = NSEntityDescription.insertNewObject(forEntityName: "Measurement", into: context)
        ret.setPrimitiveValue(accelerationsCount, forKey: "accelerationsCount")
        ret.setPrimitiveValue(vehicleContext, forKey: "context")
        ret.setPrimitiveValue(identifier, forKey: "identifier")
        ret.setPrimitiveValue(synchronized, forKey: "synchronized")
        ret.setPrimitiveValue(timestamp, forKey: "timestamp")
        ret.setPrimitiveValue(trackLength, forKey: "trackLength")
        return ret
    }

    /**
     Creates an array filled with geo location `NSManagedObject` instances usable by *CoreData* in a Version 4 Cyface database.

     - Parameters:
        - count: The amount of instances to create.
        - startTimestamp: The timestamp used for the first instance in milliseconds since the 1st of january 1970. This is increased by 1 second per location.
        - track: The track entity these new locations are going to belong to. This `NSManagedObject` must be from the same `NSManagedObjectContext` as the one provided to this method.
        - context: The `NSManagedObjectContext` to use for instance creation. This must be a valid version 4 `NSManagedObjectContext`.
     - Returns: An array containing `count` geo locations.
     */
    static func createV4GeoLocations(_ count: Int, _ startTimestamp: Int64, _ track: NSManagedObject, _ context: NSManagedObjectContext) -> [NSManagedObject] {
        var ret = [NSManagedObject]()
        for i in 0..<count {
            let geoLocation = NSEntityDescription.insertNewObject(forEntityName: "GeoLocation", into: context)
            geoLocation.setPrimitiveValue(1.0, forKey: "accuracy")
            geoLocation.setPrimitiveValue(52.0+0.01*Double(i), forKey: "lat")
            geoLocation.setPrimitiveValue(13.7+0.01*Double(i), forKey: "lon")
            geoLocation.setPrimitiveValue(1.0, forKey: "speed")
            geoLocation.setPrimitiveValue(20_000+i, forKey: "timestamp")
            geoLocation.setValue(track, forKey: "track")
            ret.append(geoLocation)
        }
        return ret
    }

    /**
     Create a measurement on the test persistence layer for serialization.

     - Parameters:
        - countOfGeoLocations: The amount of geo locations to create within the test measurement
        - countOfAccelerations: The amount of accelerations to create within the test measurement
     - Returns: The created test measurement
     - Throws:
        - Some unspecified errors from within CoreData.
        - Some internal file system error on failure of accessing the acceleration file at the required path.
     */
    static func fakeMeasurement(countOfGeoLocations: Int, countOfAccelerations: Int, persistenceLayer: PersistenceLayer) throws -> MeasurementMO {
        let measurement = try persistenceLayer.createMeasurement(at: DataCapturingService.currentTimeInMillisSince1970(), withContext: .bike)
        measurement.accelerationsCount = Int32(countOfAccelerations)
        measurement.synchronized = false
        measurement.trackLength = Double.random(in: 0..<10_000.0)

        persistenceLayer.appendNewTrack(to: measurement)
        var locations = [GeoLocation]()

        for _ in 0..<countOfGeoLocations {
            let location = GeoLocation(latitude: Double.random(in: -90.0...90.0), longitude: Double.random(in: -180.0...180.0), accuracy: Double.random(in: 0.0...20.0), speed: Double.random(in: 0.0...80.0), timestamp: DataCapturingService.currentTimeInMillisSince1970())

            locations.append(location)
        }
        try persistenceLayer.save(locations: locations, in: measurement)

        var accelerations = [Acceleration]()
        for _ in 0..<countOfAccelerations {
            let acceleration = Acceleration(timestamp: DataCapturingService.currentTimeInMillisSince1970(), x: Double.random(in: -10.0...10.0), y: Double.random(in: -10.0...10.0), z: Double.random(in: -10.0...10.0))
            accelerations.append(acceleration)
        }
        try persistenceLayer.save(accelerations: accelerations, in: measurement)

        return measurement
    }
}
