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
 - Version: 2.0.1
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

        let measurement01 = createV4Measurement(450*100, "BICYCLE", Int64(1), false, Date(timeIntervalSince1970: 10_000), 450.0, context)
        let trackOne = NSEntityDescription.insertNewObject(forEntityName: "Track", into: context)
        let trackOneGeoLocations = createV4GeoLocations(200, Date(timeIntervalSince1970: 10_000), trackOne, context, createV4GeoLocation)
        trackOne.setValue(NSOrderedSet(array: trackOneGeoLocations), forKey: "locations")
        trackOne.setValue(measurement01, forKey: "measurement")
        let trackTwo = NSEntityDescription.insertNewObject(forEntityName: "Track", into: context)
        let trackTwoGeoLocations = createV4GeoLocations(250, Date(timeIntervalSince1970: 10_300), trackTwo, context, createV4GeoLocation)
        trackTwo.setValue(NSOrderedSet(array: trackTwoGeoLocations), forKey: "locations")
        trackTwo.setValue(measurement01, forKey: "measurement")

        let measurement02 = createV4Measurement(300*100, "BICYCLE", Int64(2), false, Date(timeIntervalSince1970: 20_000), 300, context)
        let trackForMeasurementTwo = NSEntityDescription.insertNewObject(forEntityName: "Track", into: context)
        let trackForMeasurementTwoGeoLocations = createV4GeoLocations(300, Date(timeIntervalSince1970: 20_000), trackForMeasurementTwo, context, createV4GeoLocation)
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
    static func createV4Measurement(_ accelerationsCount: Int64, _ vehicleContext: String, _ identifier: Int64, _ synchronized: Bool, _ time: Date, _ trackLength: Double, _ context: NSManagedObjectContext) -> NSManagedObject {
        let ret = NSEntityDescription.insertNewObject(forEntityName: "Measurement", into: context)
        ret.setPrimitiveValue(accelerationsCount, forKey: "accelerationsCount")
        ret.setPrimitiveValue(vehicleContext, forKey: "context")
        ret.setPrimitiveValue(identifier, forKey: "identifier")
        ret.setPrimitiveValue(synchronized, forKey: "synchronized")
        ret.setPrimitiveValue(time, forKey: "timestamp")
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
    static func createV4GeoLocations(_ count: UInt64, _ startTime: Date, _ track: NSManagedObject, _ context: NSManagedObjectContext, _ locationCreator: (UInt64, Date, NSManagedObject, NSManagedObjectContext) -> NSManagedObject ) -> [NSManagedObject] {
        var ret = [NSManagedObject]()
        for i in 0..<count {
            let geoLocation = locationCreator(i, startTime, track, context)
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
    static func createV4GeoLocation(position: UInt64, startTime: Date, track: NSManagedObject, context: NSManagedObjectContext) -> NSManagedObject {
        let geoLocation = NSEntityDescription.insertNewObject(forEntityName: "GeoLocation", into: context)
        geoLocation.setPrimitiveValue(1.0, forKey: "accuracy")
        geoLocation.setPrimitiveValue(52.0+0.01*Double(position), forKey: "lat")
        geoLocation.setPrimitiveValue(13.7+0.01*Double(position), forKey: "lon")
        geoLocation.setPrimitiveValue(1.0, forKey: "speed")
        geoLocation.setPrimitiveValue(startTime.addingTimeInterval(Double(position)), forKey: "timestamp")
        geoLocation.setValue(track, forKey: "track")
        return geoLocation
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
        let measurement01 = createMeasurement(
            accelerationsCount: 10_000,
            vehicleContext: "BICYCLE",
            identifier: 1,
            synchronized: false,
            time: Date(),
            trackLength: 500,
            context: context
        )
        let track0101 = appendTrack(to: measurement01, context: context)
        createGeoLocations(count: 30, track: track0101, context: context, locationCreator: DataSetCreator.createV4GeoLocation)
        let track0102 = appendTrack(to: measurement01, context: context)
        createGeoLocations(count: 20, track: track0102, context: context, locationCreator: DataSetCreator.createV4GeoLocation)

        let measurement02 = createMeasurement(
            accelerationsCount: 20_000,
            vehicleContext: "BICYCLE",
            identifier: 2,
            synchronized: false,
            time: Date(),
            trackLength: 700,
            context: context
        )
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
    func createMeasurement(accelerationsCount: Int64, vehicleContext: String, identifier: Int64, synchronized: Bool, time: Date, trackLength: Double, context: NSManagedObjectContext) -> NSManagedObject {
        let measurement = DataSetCreator.createV4Measurement(accelerationsCount, vehicleContext, identifier, synchronized, time, trackLength, context)
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
    func createGeoLocations(count: Int64, track: NSManagedObject, context: NSManagedObjectContext, locationCreator: (UInt64, Date, NSManagedObject, NSManagedObjectContext) -> NSManagedObject) {
        let locations = DataSetCreator.createV4GeoLocations(40, Date(), track, context, locationCreator)
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
        let measurement01 = dataSetCreatorV5.createMeasurement(accelerationsCount: 10_000, vehicleContext: "BICYCLE", identifier: 1, synchronized: false, time: Date(), trackLength: 700, context: context)
        let track0101 = dataSetCreatorV5.appendTrack(to: measurement01, context: context)
        dataSetCreatorV5.createGeoLocations(count: 20, track: track0101, context: context, locationCreator: createGeoLocation)

        let measurement02 = dataSetCreatorV5.createMeasurement(accelerationsCount: 20_000, vehicleContext: "BICYCLE", identifier: 2, synchronized: false, time: Date(), trackLength: 200, context: context)
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
    func createGeoLocation(position: UInt64, startTime: Date, track: NSManagedObject, context: NSManagedObjectContext) -> NSManagedObject {
        let geoLocation = DataSetCreator.createV4GeoLocation(position: position, startTime: startTime, track: track, context: context)
        geoLocation.setPrimitiveValue(true, forKey: "isPartOfCleanedTrack")
        return geoLocation
    }
}

/**
 Event
 * time: Date
 * type: Integer 16
 * value: String
 - measurement: Measurement -> events
 GeoLocation
 * accuracy: Double
 * isPartOfCleanedTrack: Boolean            // Wird gelöscht
 * lat: Double
 * lon: Double
 * speed: Double
 * timestamp: Integer 64
 - track: Track -> locations
 Measurement
 * accelerationsCount: Integer 32        // Wird gelöscht
 * directionsCount: Integer 32            // Wird gelöscht
 * identifier: Integer 64
 * rotationsCount: Integer 32            // Wird gelöscht
 * synchronizable: Boolean
 * synchronized: Boolean
 * timestamp: Integer 64
 * trackLength: Double                    // Wird gelöscht
 - events: Event -> measurement
 - tracks: Track -> measurement
 Track
 - locations: GeoLocation -> track
 - measurement: Measurement -> tracks
 */
class DataSetCreatorV9: DataSetCreatorProtocol {
    func createData(in container: NSPersistentContainer) throws {
        let context = container.newBackgroundContext()
        let measurement01 = measurement(context: context, identifier: 0, timestamp: 1708338253000, synchronizable: true, synchronized: false, accelerationsCount: 10, directionsCount: 15, rotationsCount: 20, trackLength: 253)

        // 2 Tracks mit entsprechenden Events und Locations
        let tracks01 = [NSManagedObject]()

        let track0101 = track(context: context, measurement: measurement01)
        let locations0101 = [
            geoLocation(context: context, accuracy: 19.49, isPartOfCleanedTrack: false, lat: 51.399973, lon: 12.196312, speed: 0.0, timestamp: 1694523963999, track: track0101),
            geoLocation(context: context, accuracy: 23.87, isPartOfCleanedTrack: true, lat: 51.399973, lon: 12.196312, speed: 0.0, timestamp: 1694523964999, track: track0101),
            geoLocation(context: context, accuracy: 15.55, isPartOfCleanedTrack: false, lat: 51.399973, lon: 12.196312, speed: 0.0, timestamp: 1694523965999, track: track0101),
            geoLocation(context: context, accuracy: 13.89, isPartOfCleanedTrack: true, lat: 51.399973, lon: 12.196312, speed: 0.0, timestamp: 1694523966999, track: track0101),
            geoLocation(context: context, accuracy: 14.89, isPartOfCleanedTrack: false, lat: 51.399973, lon: 12.196312, speed: 0.0, timestamp: 1694523967999, track: track0101),
            geoLocation(context: context, accuracy: 18.18, isPartOfCleanedTrack: true, lat: 51.399973, lon: 12.196312, speed: 0.0, timestamp: 1694523968999, track: track0101),
            geoLocation(context: context, accuracy: 15.64, isPartOfCleanedTrack: false, lat: 51.399946, lon: 12.196136, speed: 0.01, timestamp: 1694523969999, track: track0101),
            geoLocation(context: context, accuracy: 9.4, isPartOfCleanedTrack: true, lat: 51.399942, lon: 12.196116, speed: 0.0, timestamp: 1694523970999, track: track0101)
        ]
        track0101.setValue(NSOrderedSet(array: locations0101), forKey: "locations")
        tracks01.append(track0101)

        let track0102 = track(context: context, measurement: measurement01)
        let locations0102 = [
            geoLocation(context: context, accuracy: 14.87, isPartOfCleanedTrack: false, lat: 51.399995, lon: 12.196409, speed: 1.93, timestamp: 1694523956223, track: track0101),
            geoLocation(context: context, accuracy: 13.41, isPartOfCleanedTrack: true, lat: 51.39998, lon: 12.196359, speed: 0.05, timestamp: 1694523957173, track: track0101),
            geoLocation(context: context, accuracy: 12.81, isPartOfCleanedTrack: true, lat: 51.399977, lon: 12.196343, speed: 0.03, timestamp: 1694523958123, track: track0101),
            geoLocation(context: context, accuracy: 12.15, isPartOfCleanedTrack: false, lat: 51.399974, lon: 12.19633, speed: 0.02, timestamp: 1694523959073, track: track0101),
            geoLocation(context: context, accuracy: 11.73, isPartOfCleanedTrack: true, lat: 51.399974, lon: 12.19633, speed: 0.0, timestamp: 1694523960023, track: track0101),
            geoLocation(context: context, accuracy: 11.41, isPartOfCleanedTrack: false, lat: 51.399973, lon: 12.196312, speed: 0.03, timestamp: 1694523960999, track: track0101),
            geoLocation(context: context, accuracy: 12.41, isPartOfCleanedTrack: true, lat: 51.399973, lon: 12.196312, speed: 0.0, timestamp: 1694523961999, track: track0101),
            geoLocation(context: context, accuracy: 10.85, isPartOfCleanedTrack: false, lat: 51.399973, lon: 12.196312, speed: 0.0, timestamp: 1694523962999, track: track0101)
        ]
        track0102.setValue(NSOrderedSet(array: locations0102), forKey: "locations")
        tracks01.append(track0102)

        let events01 = [
            event(context: context, time: Date(timeIntervalSince1970: 1708338253000), type: EventType.modalityTypeChange, value: "BICYCLE", measurement: measurement01),
            event(context: context, time: Date(timeIntervalSince1970: 1708338253000), type: EventType.lifecycleStart, value: nil, measurement: measurement01),
            event(context: context, time: Date(timeIntervalSince1970: 1708338254), type: EventType.lifecyclePause, value: nil, measurement: measurement01),
            event(context: context, time: Date(timeIntervalSince1970: 1708338255), type: EventType.lifecycleResume, value: nil, measurement: measurement01)
        ]

        measurement01.setValue(NSOrderedSet(array: tracks01))
        measurement01.setValue(NSOrderedSet(array: events01))

        let measurement02 = measurement(context: context, identifier: 1, timestamp: 1708345816000, synchronizable: false, synchronized: true, accelerationsCount: 20, directionsCount: 25, rotationsCount: 30, trackLength: 1234)
        // 1 Track mit Events und locations
        let tracks02 = [NSManagedObject]()
        let track0201 = track(context: context, measurement: measurement02)
        let locations0201 = [
            geoLocation(context: context, accuracy: 35.0, isPartOfCleanedTrack: true, lat: 51.399841, lon: 12.196419, speed: -1.0, timestamp: 1694523938373, track: track0201),
            geoLocation(context: context, accuracy: 27.43, isPartOfCleanedTrack: false, lat: 51.39987, lon: 12.196359, speed: 0.74, timestamp: 1694523942818, track: track0201),
            geoLocation(context: context, accuracy: 24.03, isPartOfCleanedTrack: true, lat: 51.399937, lon: 12.196328, speed: 0.74, timestamp: 1694523943818, track: track0201),
            geoLocation(context: context, accuracy: 22.15, isPartOfCleanedTrack: false, lat: 51.399967, lon: 12.19631, speed: 0.64, timestamp: 1694523944768, track: track0201),
            geoLocation(context: context, accuracy: 20.7, isPartOfCleanedTrack: true, lat: 51.399967, lon: 12.19631, speed: 0.0, timestamp: 1694523945718, track: track0201),
            geoLocation(context: context, accuracy: 19.27, isPartOfCleanedTrack: false, lat: 51.399967, lon: 12.19631, speed: 0.0, timestamp: 1694523946668, track: track0201),
            geoLocation(context: context, accuracy: 18.14, isPartOfCleanedTrack: true, lat: 51.399998, lon: 12.196308, speed: 0.39, timestamp: 1694523947618, track: track0201),
            geoLocation(context: context, accuracy: 17.57, isPartOfCleanedTrack: false, lat: 51.40001, lon: 12.196315, speed: 1.54, timestamp: 1694523948622, track: track0201),
            geoLocation(context: context, accuracy: 17.25, isPartOfCleanedTrack: true, lat: 51.400021, lon: 12.196319, speed: 1.19, timestamp: 1694523949572, track: track0201),
            geoLocation(context: context, accuracy: 17.09, isPartOfCleanedTrack: false, lat: 51.400014, lon: 12.196343, speed: 1.54, timestamp: 1694523950522, track: track0201),
            geoLocation(context: context, accuracy: 17.06, isPartOfCleanedTrack: true, lat: 51.40001, lon: 12.196366, speed: 1.58, timestamp: 1694523951472, track: track0201),
            geoLocation(context: context, accuracy: 16.39, isPartOfCleanedTrack: false, lat: 51.400004, lon: 12.196401, speed: 3.41, timestamp: 1694523952422, track: track0201),
            geoLocation(context: context, accuracy: 15.56, isPartOfCleanedTrack: true, lat: 51.399994, lon: 12.196374, speed: 3.41, timestamp: 1694523953372, track: track0201),
            geoLocation(context: context, accuracy: 15.15, isPartOfCleanedTrack: false, lat: 51.400001, lon: 12.196425, speed: 3.41, timestamp: 1694523954322, track: track0201),
        ]
        track0201.setValue(NSOrderedSet(array: locations0201), forKey: "locations")
        tracks02.append(track0201)
        
        let events02 = [
            event(context: context, time: Date(timeIntervalSince1970: 1708345816), type: EventType.modalityTypeChange, value: "BICYCLE", measurement: measurement02),
            event(context: context, time: Date(timeIntervalSince1970: 1708345816), type: EventType.lifecycleStart, value: nil, measurement: measurement02),
            event(context: context, time: Date(timeIntervalSince1970: 1708345817), type: EventType.lifecycleStop, value: nil, measurement: measurement02)
        ]

        measurement02.setValue(NSOrderedSet(array: tracks02), forKey: "tracks")
        measurement02.setValue(NSOrderedSet(array: events02), forKey: "events")

        try context.save()
    }

    func geoLocation(context: NSManagedObjectContext, accuracy: Double, isPartOfCleanedTrack: Boolean, lat: Double, lon: Double, speed: Double, timestamp: Int64, track: NSManagedObject) -> NSManagedObject{
        let location = NSEntityDescription.insertNewObject(forEntityName: "GeoLocation", into: context)
        location.setPrimitiveValue(accuracy, forKey: "accuracy")
        location.setPrimitiveValue(isPartOfCleanedTrack, forKey: "accuracy")
        location.setPrimitiveValue(lat, forKey: "accuracy")
        location.setPrimitiveValue(lon, forKey: "accuracy")
        location.setPrimitiveValue(speed, forKey: "accuracy")
        location.setPrimitiveValue(timestamp, forKey: "accuracy")
        location.setValue(track, forKey: "track")

        return location
    }

    func track(context: NSManagedObjectContext, measurement: NSManagedObject) -> NSManagedObject {
        let track = NSEntityDescription.insertNewObject(forEntityName: "Track", into: context)
        track.setValue(measurement, forKey: "measurement")
    }

    func measurement(
        context: NSManagedObjectContext,
        identifier: Int64,
        timestamp: Int64,
        synchronizable: Bool,
        synchronized: Bool,
        accelerationsCount: Int64,
        directionsCount: Int64,
        rotationsCount: Int64,
        trackLength: Int,
        tracks: [NSManagedObject],
        events: [NSManagedObject]
    ) -> NSManagedObject {
        let measurement = NSEntityDescription.insertNewObject(forEntityName: "Measurement", into: context)
        measurement.setPrimitiveValue(accelerationsCount, forKey: "accelerationsCount")
        measurement.setPrimitiveValue(directionsCount, forKey: "directionsCount")
        measurement.setPrimitiveValue(rotationsCount, forKey: "rotationsCount")
        measurement.setPrimitiveValue(identifier, forKey: "identifier")
        // Nicht synchronisiert
        measurement.setPrimitiveValue(NSNumber(bool: synchronizable), forKey: "synchronizable")
        measurement.setPrimitiveValue(NSNumber(booL: synchronized), forKey: "synchronized")
        measurement.setPrimitiveValue(timestamp, forKey: "timestamp")
        measurement.setPrimitiveValue(trackLength, forKey: "trackLength")

        return measurement
    }

    func event(
        context: NSManagedObjectContext,
        time: Date,
        type: Int16,
        value: String?,
        measurement: NSManagedObject
    ) -> NSManagedObject {
        let event = NSEntityDescription.insertNewObject(forEntityName: "Event", into: context)
        event.setPrimitiveValue(time, forKey: "time")
        event.setPrimitiveValue(type, forKey: "type")
        event.setPrimitiveValue(value, forKey: "value")
        event.setValue(measurement, forKey: "measurement")
    }
}
/*
 userId    username    deviceId    measurementId    trackId    timestamp [ms]    latitude    longitude    speed [m/s]    accuracy [m]    modalityType    modalityTypeDistance [m]    distance [m]    modalityTypeTravelTime [ms]    travelTime [ms]
 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523938373    51.399841    12.196419    -1.0    35.0    BICYCLE    0.0    0.0    0    0
 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523942818    51.39987    12.196359    0.74    27.43    BICYCLE    0.005265313501292628    0.005265313501292628    4445    4445
 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523943818    51.399937    12.196328    0.74    24.03    BICYCLE    0.013019553339726764    0.013019553339726764    5445    5445
 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523944768    51.399967    12.19631    0.64    22.15    BICYCLE    0.01658145403568394    0.01658145403568394    6395    6395
 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523945718    51.399967    12.19631    0.0    20.7    BICYCLE    0.01658145403568394    0.01658145403568394    7345    7345
 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523946668    51.399967    12.19631    0.0    19.27    BICYCLE    0.01658145403568394    0.01658145403568394    8295    8295
 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523947618    51.399998    12.196308    0.39    18.14    BICYCLE    0.02003128788725555    0.02003128788725555    9245    9245
 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523948622    51.40001    12.196315    1.54    17.57    BICYCLE    0.021451243437245065    0.021451243437245065    10249    10249
 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523949572    51.400021    12.196319    1.19    17.25    BICYCLE    0.022705469015569017    0.022705469015569017    11199    11199
 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523950522    51.400014    12.196343    1.54    17.09    BICYCLE    0.02454336293449937    0.02454336293449937    12149    12149
 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523951472    51.40001    12.196366    1.58    17.06    BICYCLE    0.0261997580126141    0.0261997580126141    13099    13099
 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523952422    51.400004    12.196401    3.41    16.39    BICYCLE    0.02871778032121593    0.02871778032121593    14049    14049
 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523953372    51.399994    12.196374    3.41    15.56    BICYCLE    0.030896025034687736    0.030896025034687736    14999    14999
 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523954322    51.400001    12.196425    3.41    15.15    BICYCLE    0.034518619034428794    0.034518619034428794    15949    15949
 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523955272    51.400011    12.196468    3.41    15.15    BICYCLE    0.03770213235741646    0.03770213235741646    16899    16899


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523956223    51.399995    12.196409    1.93    14.87    BICYCLE    0.04216504662259363    0.04216504662259363    17850    17850
 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523957173    51.39998    12.196359    0.05    13.41    BICYCLE    0.04601384487593153    0.04601384487593153    18800    18800
 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523958123    51.399977    12.196343    0.03    12.81    BICYCLE    0.047172845369006636    0.047172845369006636    19750    19750
 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523959073    51.399974    12.19633    0.02    12.15    BICYCLE    0.048134403279708575    0.048134403279708575    20700    20700
 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523960023    51.399974    12.19633    0.0    11.73    BICYCLE    0.048134403279708575    0.048134403279708575    21650    21650
 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523960999    51.399973    12.196312    0.03    11.41    BICYCLE    0.04938804552403328    0.04938804552403328    22626    22626
 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523961999    51.399973    12.196312    0.0    12.41    BICYCLE    0.04938804552403328    0.04938804552403328    23626    23626
 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523962999    51.399973    12.196312    0.0    10.85    BICYCLE    0.04938804552403328    0.04938804552403328    24626    24626
 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523963999    51.399973    12.196312    0.0    19.49    BICYCLE    0.04938804552403328    0.04938804552403328    25626    25626
 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523964999    51.399973    12.196312    0.0    23.87    BICYCLE    0.04938804552403328    0.04938804552403328    26626    26626
 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523965999    51.399973    12.196312    0.0    15.55    BICYCLE    0.04938804552403328    0.04938804552403328    27626    27626
 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523966999    51.399973    12.196312    0.0    13.89    BICYCLE    0.04938804552403328    0.04938804552403328    28626    28626
 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523967999    51.399973    12.196312    0.0    14.89    BICYCLE    0.04938804552403328    0.04938804552403328    29626    29626
 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523968999    51.399973    12.196312    0.0    18.18    BICYCLE    0.04938804552403328    0.04938804552403328    30626    30626
 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523969999    51.399946    12.196136    0.01    15.64    BICYCLE    0.0619612754576728    0.0619612754576728    31626    31626
 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523970999    51.399942    12.196116    0.0    9.4    BICYCLE    0.06341827137607274    0.06341827137607274    32626    32626


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523971999    51.399942    12.196116    0.0    9.34    BICYCLE    0.06341827137607274    0.06341827137607274    33626    33626


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523972999    51.399936    12.196083    0.02    9.3    BICYCLE    0.06580279459323302    0.06580279459323302    34626    34626


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523974000    51.399933    12.196066    0.03    9.26    BICYCLE    0.06702839556796346    0.06702839556796346    35627    35627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523975000    51.399906    12.196001    0.1    6.71    BICYCLE    0.07244563686562949    0.07244563686562949    36627    36627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523976000    51.399897    12.195959    0.05    6.69    BICYCLE    0.07552635282640119    0.07552635282640119    37627    37627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523977000    51.399891    12.195931    0.13    6.74    BICYCLE    0.07758016376840751    0.07758016376840751    38627    38627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523978000    51.399886    12.195897    0.27    6.84    BICYCLE    0.08000346621708843    0.08000346621708843    39627    39627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523979000    51.39988    12.195885    0.42    6.85    BICYCLE    0.0810702932850205    0.0810702932850205    40627    40627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523980000    51.39988    12.195921    0.15    6.85    BICYCLE    0.08356770069286477    0.08356770069286477    41627    41627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523981000    51.399881    12.195943    0.19    6.78    BICYCLE    0.08509793943352333    0.08509793943352333    42627    42627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523982000    51.399885    12.195977    0.47    6.6    BICYCLE    0.08749817219113541    0.08749817219113541    43627    43627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523983000    51.399877    12.196043    0.76    6.3    BICYCLE    0.09216236688244325    0.09216236688244325    44627    44627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523984000    51.399881    12.196062    1.08    6.08    BICYCLE    0.09355346492115808    0.09355346492115808    45627    45627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523985000    51.399874    12.196049    1.44    5.99    BICYCLE    0.09474475395819588    0.09474475395819588    46627    46627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523986000    51.399875    12.196055    1.36    5.8    BICYCLE    0.09517558521172356    0.09517558521172356    47627    47627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523987000    51.399872    12.196025    1.97    5.73    BICYCLE    0.09728332343682956    0.09728332343682956    48627    48627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523988000    51.399867    12.195998    2.63    5.61    BICYCLE    0.09923715211906675    0.09923715211906675    49627    49627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523989000    51.399858    12.195964    2.97    5.44    BICYCLE    0.10179933918070824    0.10179933918070824    50627    50627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523990000    51.399844    12.195941    2.76    5.36    BICYCLE    0.10402851810717206    0.10402851810717206    51627    51627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523991000    51.399848    12.195928    2.08    5.27    BICYCLE    0.10503407685862014    0.10503407685862014    52627    52627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523992000    51.399848    12.195901    2.58    5.04    BICYCLE    0.10690713372503119    0.10690713372503119    53627    53627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523993000    51.399846    12.195855    3.13    5.04    BICYCLE    0.11010600749403043    0.11010600749403043    54627    54627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523994000    51.399846    12.195811    3.17    5.03    BICYCLE    0.11315839659479363    0.11315839659479363    55627    55627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523995000    51.399843    12.195774    2.72    5.04    BICYCLE    0.11574676437362073    0.11574676437362073    56627    56627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523996000    51.399844    12.195727    2.6    5.06    BICYCLE    0.11900916661252112    0.11900916661252112    57627    57627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523997000    51.399849    12.195695    2.06    5.05    BICYCLE    0.12129764855214363    0.12129764855214363    58627    58627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523998000    51.399848    12.195663    2.11    5.03    BICYCLE    0.12352035088857895    0.12352035088857895    59627    59627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694523999000    51.399848    12.19564    1.62    5.0    BICYCLE    0.12511591784882764    0.12511591784882764    60627    60627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694524000000    51.399843    12.195618    1.7    5.0    BICYCLE    0.12674022620918393    0.12674022620918393    61627    61627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694524001000    51.399842    12.1956    1.52    4.98    BICYCLE    0.12799387201581153    0.12799387201581153    62627    62627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694524002000    51.399835    12.1956    0.88    4.97    BICYCLE    0.12877223650193842    0.12877223650193842    63627    63627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694524003000    51.399843    12.195604    0.11    4.97    BICYCLE    0.129704071587459    0.129704071587459    64627    64627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694524004000    51.399839    12.195599    0.51    4.9    BICYCLE    0.1302681128416289    0.1302681128416289    65627    65627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694524005000    51.399834    12.195598    0.24    4.9    BICYCLE    0.1308283987828199    0.1308283987828199    66627    66627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694524006000    51.399834    12.195598    0.51    4.9    BICYCLE    0.1308283987828199    0.1308283987828199    67627    67627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694524007000    51.399816    12.195604    1.13    4.9    BICYCLE    0.13287272963311242    0.13287272963311242    68627    68627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694524008000    51.399813    12.1956    1.07    4.92    BICYCLE    0.13330664156670685    0.13330664156670685    69627    69627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694524009000    51.399805    12.195595    1.47    4.93    BICYCLE    0.13426143456386527    0.13426143456386527    70627    70627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694524010000    51.39979    12.195599    1.39    4.96    BICYCLE    0.135952283744662    0.135952283744662    71627    71627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694524011000    51.399768    12.195594    1.71    4.96    BICYCLE    0.1384230408643644    0.1384230408643644    72627    72627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694524012000    51.399745    12.195601    1.93    4.95    BICYCLE    0.14102621898402423    0.14102621898402423    73627    73627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694524013000    51.399723    12.195606    1.89    4.92    BICYCLE    0.14349697615163504    0.14349697615163504    74627    74627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694524014000    51.399692    12.195614    2.52    4.91    BICYCLE    0.14698840967369772    0.14698840967369772    75627    75627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694524015000    51.399661    12.19563    3.13    4.89    BICYCLE    0.1506097524027733    0.1506097524027733    76627    76627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694524016000    51.399626    12.19565    3.5    4.88    BICYCLE    0.15474149722353406    0.15474149722353406    77627    77627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694524017000    51.399588    12.195667    3.69    4.86    BICYCLE    0.1591283987461501    0.1591283987461501    78627    78627


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694524018001    51.399547    12.195683    4.02    4.86    BICYCLE    0.16382056599265438    0.16382056599265438    79628    79628


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694524019001    51.399506    12.195697    4.12    4.86    BICYCLE    0.16848186186194936    0.16848186186194936    80628    80628


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694524020001    51.399474    12.19571    3.7    4.88    BICYCLE    0.17215260937063348    0.17215260937063348    81628    81628


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694524021001    51.399449    12.195722    3.16    4.9    BICYCLE    0.1750544557422048    0.1750544557422048    82628    82628


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694524022001    51.399423    12.195737    2.89    4.92    BICYCLE    0.1781270956227802    0.1781270956227802    83628    83628


 72a0869a-e590-44a2-8820-d1e760f4be64    klemens.muthmann@cyface.de    31A805CB-4F0B-4153-A835-A66483800A02    1    0    1694524023001    51.399399    12.195748    2.65    4.93    BICYCLE    0.1809027346611604    0.1809027346611604    84628    84628
 */
