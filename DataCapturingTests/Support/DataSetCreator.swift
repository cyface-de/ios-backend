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
 - Version: 2.0.0
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

    /**
     Creates data in the version 4 format of the Cyface database schema. This version added individual tracks to measurements

     - Parameter in: The container to create the data in
     */
    static func createV4Data(in container: NSPersistentContainer) throws {
        let context = container.newBackgroundContext()

        let measurement01 = createV4Measurement(450*100, "BICYCLE", Int64(1), false, Int64(10_000), 450.0, context)
        let trackOne = NSEntityDescription.insertNewObject(forEntityName: "Track", into: context)
        let trackOneGeoLocations = createV4GeoLocations(200, Int64(10_000), trackOne, context, createV4GeoLocation)
        trackOne.setValue(NSOrderedSet(array: trackOneGeoLocations), forKey: "locations")
        trackOne.setValue(measurement01, forKey: "measurement")
        let trackTwo = NSEntityDescription.insertNewObject(forEntityName: "Track", into: context)
        let trackTwoGeoLocations = createV4GeoLocations(250, 10_300, trackTwo, context, createV4GeoLocation)
        trackTwo.setValue(NSOrderedSet(array: trackTwoGeoLocations), forKey: "locations")
        trackTwo.setValue(measurement01, forKey: "measurement")

        let measurement02 = createV4Measurement(300*100, "BICYCLE", Int64(2), false, Int64(20_000), 300, context)
        let trackForMeasurementTwo = NSEntityDescription.insertNewObject(forEntityName: "Track", into: context)
        let trackForMeasurementTwoGeoLocations = createV4GeoLocations(300, Int64(20_000), trackForMeasurementTwo, context, createV4GeoLocation)
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
        - locationCreator: A function to create one geo location.
     - Returns: An array containing `count` geo locations.
     */
    static func createV4GeoLocations(_ count: Int64, _ startTimestamp: Int64, _ track: NSManagedObject, _ context: NSManagedObjectContext, _ locationCreator: (Int64,Int64, NSManagedObject, NSManagedObjectContext) -> NSManagedObject ) -> [NSManagedObject] {
        var ret = [NSManagedObject]()
        for i in 0..<count {
            let geoLocation = locationCreator(i, startTimestamp, track, context)
            ret.append(geoLocation)
        }
        return ret
    }

    /**
     A function to create a single `GeoLocation` in the version 4 data format.

     - Parameters:
        - position: The position of the `GeoLocation` within the current `Track`.
        - startTimestamp: The timestamp of the first `GeoLocation` in the current `Track` in milliseconds since the 1st of January 1970.
        - track: The `Track` to add the `GeoLocation` to.
        - context: The managed object context to save the newly created `GeoLocation` in.
     */
    static func createV4GeoLocation(position: Int64, startTimestamp: Int64, track: NSManagedObject, context: NSManagedObjectContext) -> NSManagedObject {
        let geoLocation = NSEntityDescription.insertNewObject(forEntityName: "GeoLocation", into: context)
        geoLocation.setPrimitiveValue(1.0, forKey: "accuracy")
        geoLocation.setPrimitiveValue(52.0+0.01*Double(position), forKey: "lat")
        geoLocation.setPrimitiveValue(13.7+0.01*Double(position), forKey: "lon")
        geoLocation.setPrimitiveValue(1.0, forKey: "speed")
        geoLocation.setPrimitiveValue(startTimestamp + position, forKey: "timestamp")
        geoLocation.setValue(track, forKey: "track")
        return geoLocation
    }

    /**
     Create a measurement on the test persistence layer for serialization.

     - Parameters:
        - countOfGeoLocations: The amount of geo locations to create within the test measurement
        - countOfAccelerations: The amount of accelerations to create within the test measurement
        - persistenceLayer: The `PersistenceLayer` used to create the fake measurement
     - Returns: The created test measurement
     - Throws:
        - Some unspecified errors from within CoreData.
        - Some internal file system error on failure of accessing the acceleration file at the required path.
     */
    static func fakeMeasurement(countOfGeoLocations: Int, countOfAccelerations: Int, persistenceLayer: PersistenceLayer) throws -> MeasurementMO {
        let measurement = try persistenceLayer.createMeasurement(at: DataCapturingService.currentTimeInMillisSince1970(), inMode: "BICYCLE")
        measurement.accelerationsCount = Int32(countOfAccelerations)
        measurement.synchronized = false
        measurement.trackLength = Double.random(in: 0..<10_000.0)

        persistenceLayer.appendNewTrack(to: measurement)
        var locations = [GeoLocation]()

        for _ in 0..<countOfGeoLocations {
            let location = GeoLocation(latitude: Double.random(in: -90.0...90.0), longitude: Double.random(in: -180.0...180.0), accuracy: Double.random(in: 0.0...20.0), speed: Double.random(in: 0.0...80.0), timestamp: DataCapturingService.currentTimeInMillisSince1970(), isValid: true)

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

/**
 The base protocol for all data set creators, starting from version 5.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 4.6.0
 */
protocol DataSetCreatorProtocol {

    /**
     Creates data within the provided `NSPersistentContainer`. This container must support the correct model version.

     - Parameter in: The container to save the create data to.
     */
    func createData(in container: NSPersistentContainer) throws
}

/**
 A data set creator creating a data set within an `NSPersistentContainer` of a version 5 database.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 4.6.0
 */
class DataSetCreatorV5: DataSetCreatorProtocol {

    func createData(in container: NSPersistentContainer) throws {
        let context = container.newBackgroundContext()
        let measurement01 = createMeasurement(accelerationsCount: 10_000, vehicleContext: "BICYCLE", identifier: 1, synchronized: false, timestamp: DataCapturingService.currentTimeInMillisSince1970(), trackLength: 500, context: context)
        let track0101 = appendTrack(to: measurement01, context: context)
        createGeoLocations(count: 30, track: track0101, context: context, locationCreator: DataSetCreator.createV4GeoLocation)
        let track0102 = appendTrack(to: measurement01, context: context)
        createGeoLocations(count: 20, track: track0102, context: context, locationCreator: DataSetCreator.createV4GeoLocation)

        let measurement02 = createMeasurement(accelerationsCount: 20_000, vehicleContext: "BICYCLE", identifier: 2, synchronized: false, timestamp: DataCapturingService.currentTimeInMillisSince1970(), trackLength: 700, context: context)
        let track0201 = appendTrack(to: measurement02, context: context)
        createGeoLocations(count: 40, track: track0201, context: context, locationCreator: DataSetCreator.createV4GeoLocation)

        try context.save()
    }

    /**
     Create a measurement in the version 5 data format.

     - Parameters:
        - accelerationsCount: The number of accelerations to "simulate" with the created measurement. These accelerations are not truly created, but the corresponding field is set to the provided value.
        - vehicleContext: The vehicle the measurement was supposed to be done with.
        - identifier: The identifier for the new measurement.
        - synchronized: Whether the measurement is synchronized or not.
        - timestamp: The time in milliseconds since the 1st of January 1970, when this measurement should have happended.
        - trackLength: The summed up length of all tracks in the measurement in meters.
        - context: A CoreData `NSManagedObjectContext` used to create and store the new measurement.
     - Returns: An `NSManagedObject` representing the created measurement.
     */
    func createMeasurement(accelerationsCount: Int64, vehicleContext: String, identifier: Int64, synchronized: Bool, timestamp: Int64, trackLength: Double, context: NSManagedObjectContext) -> NSManagedObject {
        let measurement = DataSetCreator.createV4Measurement(accelerationsCount, vehicleContext, identifier, synchronized, timestamp, trackLength, context)
        measurement.setPrimitiveValue(false, forKey: "synchronizable")
        return measurement
    }

    /**
     Adds a track to the end of the list of tracks of an already created measurement.

     - Parameters:
        - to: The measurement to append the track to.
        - context: The `NSManagedObjectContext` used to create and store the new track.
     - Returns: The newly created track as an `NSManagedObject`.
     */
    func appendTrack(to measurement: NSManagedObject, context: NSManagedObjectContext) -> NSManagedObject {
        let track = NSEntityDescription.insertNewObject(forEntityName: "Track", into: context)
        track.setValue(measurement, forKey: "measurement")
        return track
    }

    /**
     Create a number of geo locations with random values and add them to the end of a track.

     - Parameters:
        - count: The number of geo locations to add
        - track: The track to add the geo locations to
        - context: An `NSManagedObjectContext` used to create and store the newly created geo locations. This context must also contain the provided track.
        - locationCreator: A function creating individual geo locations.
     */
    func createGeoLocations(count: Int64, track: NSManagedObject, context: NSManagedObjectContext, locationCreator: (Int64, Int64, NSManagedObject, NSManagedObjectContext) -> NSManagedObject) {
        let locations = DataSetCreator.createV4GeoLocations(40, DataCapturingService.currentTimeInMillisSince1970(), track, context, locationCreator)
        track.setValue(NSOrderedSet(array: locations), forKey: "locations")
    }
}

/**
 A data set creator creating a data set within an `NSPersistentContainer` of a version 6 database.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 4.6.0
 */
class DataSetCreatorV6: DataSetCreatorProtocol {

    /// A reference to version 5 data set creator used to create all the data that did not change.
    private let dataSetCreatorV5 = DataSetCreatorV5()

    func createData(in container: NSPersistentContainer) throws {
        let context = container.newBackgroundContext()
        let measurement01 = dataSetCreatorV5.createMeasurement(accelerationsCount: 10_000, vehicleContext: "BICYCLE", identifier: 1, synchronized: false, timestamp: DataCapturingService.currentTimeInMillisSince1970(), trackLength: 700, context: context)
        let track0101 = dataSetCreatorV5.appendTrack(to: measurement01, context: context)
        dataSetCreatorV5.createGeoLocations(count: 20, track: track0101, context: context, locationCreator: createGeoLocation)

        let measurement02 = dataSetCreatorV5.createMeasurement(accelerationsCount: 20_000, vehicleContext: "BICYCLE", identifier: 2, synchronized: false, timestamp: DataCapturingService.currentTimeInMillisSince1970(), trackLength: 200, context: context)
        let track0201 = dataSetCreatorV5.appendTrack(to: measurement02, context: context)
        dataSetCreatorV5.createGeoLocations(count: 5, track: track0201, context: context, locationCreator: createGeoLocation)
        let track0202 = dataSetCreatorV5.appendTrack(to: measurement02, context: context)
        dataSetCreatorV5.createGeoLocations(count: 10, track: track0202, context: context, locationCreator: createGeoLocation)

        try context.save()
    }

    /**
     Create a single version 6 geo location.

     - Parameters:
        - position: The position of the new geo location within its track.
        - startTimestamp: The start timestamp of the track.
        - track: The track to add the new geo location to.
        - context: An `NSManagedObjectContext` used to create and store the new geo location. This must be the same context, that created the track object.
     - Returns: A new geo location as `NSManagedObject`.
    */
    func createGeoLocation(position: Int64, startTimestamp: Int64, track: NSManagedObject, context: NSManagedObjectContext) -> NSManagedObject {
        let geoLocation = DataSetCreator.createV4GeoLocation(position: position, startTimestamp: startTimestamp, track: track, context: context)
        geoLocation.setPrimitiveValue(true, forKey: "isPartOfCleanedTrack")
        return geoLocation
    }
}
