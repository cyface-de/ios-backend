/*
 * Copyright 2017 - 2022 Cyface GmbH
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
import os.log

/**
 An instance of an object of this class is a wrapper around the CoreData data storage used by the capturing service. It allows CRUD operations on measurements, geo locations and accelerations.
 
 All entities produced by a `PersistenceLayer` are not thread save and thus should not be used outside the calling thread.
 If multiple calls to this API are necessary, it is necessary to set an `NSManagedObjectContext` for the property `PersistenceLayer.context`.
 The creation of this context needs to be carried out on the same thread as the API calls.

 A valid usage pattern is to create a new `PersistenceLayer` instance as part of a custom method accessing the data storage and initialize the API. Using a `PersistenceLayer` as global state can result in strange errors resulting from CoreData.
 
 Read access is public while manipulation of the data stored is restricted to the framework.
 
 - Author: Klemens Muthmann
 - Version: 6.2.0
 - Since: 1.0.0
 */
public class PersistenceLayer {

    // MARK: - Properties

    /// Identifies log messages comming from this class.
    private static let log = OSLog(subsystem: "de.cyface", category: "PersistenceLayer")

    /// Manager encapsulating the CoreData stack.
    private let manager: CoreDataManager

    /// The identifier that has been assigned the last to a new `Measurement`.
    var lastIdentifier: Int64?

    /// Used to update a measurements length, each time new locations are added.
    private let distanceCalculator: DistanceCalculationStrategy

    /// The current `NSManagedObjectContext` used by this persistence layer. This has to be reset if the layer is used on a different thread. If it is `nil` each method is going to use its own context, which can cause problems if model objects are used between those methods.
    public var context: NSManagedObjectContext {
        return manager.backgroundContext
    }

    // MARK: - Initializers

    /**
     Public constructor usable by external callers.

     - Parameters:
        - withDistanceCalculator: An algorithm used to calculate the distance between geo locations.
        - manager: A manager for the CoreData stack use by this `PersistenceLayer`.
     */
    public init(onManager manager: CoreDataManager, withDistanceCalculator: DistanceCalculationStrategy = DefaultDistanceCalculationStrategy()) {
        self.distanceCalculator = withDistanceCalculator

        self.manager = manager
    }

    // MARK: - Database Writing Methods

    /**
     Creates a new `MeasurementMO` in data storage.

     - Parameters:
        - at: The time the measurement has been started at in milliseconds since the first of january 1970 (epoch).
        - inMode: The transportation mode the new measurement is created in.
     - Returns: The newly created model object for the measurement.
     - Throws: `PersistenceError.inconsistentState`, Some unspecified errors from within *CoreData*.
     */
    func createMeasurement(at timestamp: Int64, inMode mode: String) throws -> Measurement {
        return try manager.wrapInContextReturn { context in
            // This checks if a measurement with that identifier already exists and generates a new identifier until it finds one with no corresponding measurement. This is required to handle legacy data and installations, that still have measurements with falsely generated data.
            var identifier = try nextIdentifier()
            while try load(measurementIdentifiedBy: identifier, from: context) != nil {
                identifier = try nextIdentifier()
            }

            let measurementMO = MeasurementMO(context: context)
            measurementMO.timestamp = timestamp
            measurementMO.identifier = identifier
            measurementMO.synchronized = false
            measurementMO.synchronizable = false
            try context.save()

            var measurement = try Measurement(managedObject: measurementMO)
            _ = try createEvent(of: .modalityTypeChange, withValue: mode, parent: &measurement)

            return measurement
        }
    }

    /**
     This adds a new track to the end of the list of tracks of the provided measurement. New locations are always written to the last track. You need to call this method before adding any locations to a measurement.

     - Parameter to: The measurement to add the new track to.
     */
    func appendNewTrack(to measurement: inout Measurement) throws {
        try manager.wrapInContext { context in
            guard let measurementObjectId = measurement.objectId else {
                throw PersistenceError.inconsistentState
            }

            guard let measurementMO = try context.existingObject(with: measurementObjectId) as? MeasurementMO else {
                throw PersistenceError.inconsistentState
            }
            let trackMO = TrackMO(context: context)
            measurementMO.addToTracks(trackMO)

            try context.save()
            measurement.tracks.append(try Track(managedObject: trackMO, parent: measurement))
        }
    }

    /**
     Creates a new `Event` at the current time.

     - Parameters:
        - of: The type of the logged `Event`.
        - withValue: An optional value providing further information about the event
     */
    public func createEvent(of type: EventType, withValue: String? = nil, parent: inout Measurement) throws -> Event {
        return try manager.wrapInContextReturn { context in
            let eventMO = EventMO(context: context)
            eventMO.typeEnum = type
            eventMO.time = NSDate(timeIntervalSince1970: Double(DataCapturingService.currentTimeInMillisSince1970()) / 1000.0)
            eventMO.value = withValue
            guard let measurementMO = try load(measurementIdentifiedBy: parent.identifier, from: context) else {
                throw PersistenceError.inconsistentState
            }
            measurementMO.addToEvents(eventMO)
            let event = Event(managedObject: eventMO, parent: parent)
            parent.events.append(event)

            try context.save()
            return event
        }
    }

    /**
     Deletes the measurement from the data storag.
     
     - Parameters:
        - measurement: The measurement to delete from the data storage.
     - Throws: `PersistenceError.measurementNotLoadable`, Some unspecified errors from within CoreData, Some internal file system error on failure of creating or accessing the accelerations file at the required path.
     */
    public func delete(measurement: Int64) throws {
        try manager.wrapInContext { context in
            let measurementIdentifier = measurement
            guard let measurement = try load(measurementIdentifiedBy: measurement, from: context) else {
                throw PersistenceError.measurementNotLoadable(measurementIdentifier)
            }

            let localMeasurement = try Measurement(managedObject: measurement)
            let accelerationFile = SensorValueFile(fileType: SensorValueFileType.accelerationValueType)
            try accelerationFile.remove(from: localMeasurement)
            let rotationsFile = SensorValueFile(fileType: SensorValueFileType.rotationValueType)
            try rotationsFile.remove(from: localMeasurement)
            let directionsFile = SensorValueFile(fileType: SensorValueFileType.directionValueType)
            try directionsFile.remove(from: localMeasurement)
            context.delete(measurement)
            try context.save()
        }
    }

    /**
     Deletes everything from the data storage.
     
     - Throws: Some unspecified errors from within CoreData, Some internal file system error on failure of creating the file at the required path.
     */
    func delete() throws {
        try manager.wrapInContext { context in
            let request = MeasurementMO.fetchRequest()
            let accelerationsFile = SensorValueFile(fileType: SensorValueFileType.accelerationValueType)
            let rotationsFile = SensorValueFile(fileType: SensorValueFileType.rotationValueType)
            let directionsFile = SensorValueFile(fileType: SensorValueFileType.directionValueType)

            for measurementMO in try context.fetch(request) {
                let measurement = try Measurement(managedObject: measurementMO)
                try accelerationsFile.remove(from: measurement)
                try rotationsFile.remove(from: measurement)
                try directionsFile.remove(from: measurement)
                context.delete(measurementMO)
            }
            try context.save()
        }
    }

    /**
     Deletes one event from the database.

     - Parameter event: The event to delete
     */
    public func delete(event: Event) throws {
        try manager.wrapInContext { context in
            guard let objectId = event.objectId else {
                throw PersistenceError.inconsistentState
            }

            let request = EventMO.fetchRequest()
            request.predicate = NSPredicate(format: "objectID = %@", objectId)
            let fetchResult = try context.fetch(request)
            guard fetchResult.count==1, let eventMO = fetchResult.first else {
                throw PersistenceError.inconsistentState
            }
            context.delete(eventMO)
            try context.save()
        }
    }

    /**
     Strips the provided measurement of all accelerations.
     
     - Parameter measurement: The measurement to strip of accelerations.
     - Throws: `PersistenceError.measurementNotLoadable`, Some unspecified errors from within CoreData, Some internal file system error on failure of creating or accessing the accelerations file at the required path.
     */
    func clean(measurement: Int64) throws {
        try manager.wrapInContext { context in
            let measurementIdentifier = measurement
            guard let measurementMO = try load(measurementIdentifiedBy: measurementIdentifier, from: context) else {
                throw PersistenceError.measurementNotLoadable(measurementIdentifier)
            }

            measurementMO.synchronized = true
            measurementMO.accelerationsCount = 0
            measurementMO.directionsCount = 0
            measurementMO.rotationsCount = 0
            let localMeasurement = try Measurement(managedObject: measurementMO)
            let accelerationsFile = SensorValueFile(fileType: SensorValueFileType.accelerationValueType)
            try accelerationsFile.remove(from: localMeasurement)
            let rotationsFile = SensorValueFile(fileType: SensorValueFileType.rotationValueType)
            try rotationsFile.remove(from: localMeasurement)
            let directionsFile = SensorValueFile(fileType: SensorValueFileType.directionValueType)
            try directionsFile.remove(from: localMeasurement)

            try context.save()
        }
    }

    /**
     Stores the provided `locations` to the most recent track in the measurement. Please make sure to call `appendNewTrack(:to)` with the same measurement at least once before using this method.

     - Parameters:
        - locations: An array of `GeoLocation` instances, ordered by timestamp to store in the database.
        - in: The measurement to store the `location` and `accelerations` to.
     - Throws: `PersistenceError.dataNotLoadable`, Some unspecified errors from within CoreData.
     */
    func save(locations: [LocationCacheEntry], in measurement: inout Measurement) throws {
        try manager.wrapInContext { context in

            guard let measurementMO = try load(measurementIdentifiedBy: measurement.identifier, from: context) else {
                throw PersistenceError.measurementNotLoadable(measurement.identifier)
            }
            guard let trackMO = measurementMO.tracks?.lastObject as? TrackMO else {
                throw PersistenceError.dataNotLoadable(measurement: measurement.identifier)
            }
            guard var track = measurement.tracks.last else {
                throw PersistenceError.inconsistentState
            }

            let geoLocationFetchRequest = GeoLocationMO.fetchRequest()
            geoLocationFetchRequest.fetchLimit = 1
            let maxTimestampInTrackPredicate = NSPredicate(format: "track==%@ AND isPartOfCleanedTrack==%@", trackMO, NSNumber(value: true))
            geoLocationFetchRequest.predicate = maxTimestampInTrackPredicate
            geoLocationFetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            geoLocationFetchRequest.resultType = .managedObjectResultType
            let capturedLocations = try context.fetch(geoLocationFetchRequest)
            var lastCapturedLocation = capturedLocations.first
            var distance = 0.0

            try locations.forEach { location in
                let geoLocation = try GeoLocation(latitude: location.latitude, longitude: location.longitude, accuracy: location.accuracy, speed: location.speed, timestamp: Int64(location.timestamp.timeIntervalSince1970 * 1000.0), isValid: location.isValid, parent: &track)
                let dbLocation = GeoLocationMO(location: geoLocation, parent: trackMO, context: context)

                if dbLocation.isPartOfCleanedTrack {
                    if let lastCapturedLocation = lastCapturedLocation {
                        let delta = self.distanceCalculator.calculateDistance(from: lastCapturedLocation, to: dbLocation)
                        distance += delta
                    }
                    lastCapturedLocation = dbLocation
                }
            }

            measurementMO.trackLength += distance
            measurement.trackLength = measurementMO.trackLength

            try context.save()
        }
    }

    /**
     Stores the provided `SensorValue`-objects to the provided measurement. The default value for each array is an empty array. This allows to store only one type of `SensorValue`.

     - Parameters:
        - accelerations: An array of acceleration `SensorValue` instances to store.
        - rotations: An array of rotation `SensorValue` instances to store.
        - directions: An array of direction `SensorValue` instances to store.
        - in: The measurement to store the `accelerations` to.
     - Throws: Some internal file system error on failure of accessing the acceleration file at the required path.
     */
    func save(accelerations: [SensorValue] = [], rotations: [SensorValue] = [], directions: [SensorValue] = [], in measurement: inout Measurement) throws {
        try manager.wrapInContext { context in

        debugPrint("Storing \(accelerations.count) accelerations \(rotations.count) rotations and \(directions.count) directions.")

            guard let measurementObjectId = measurement.objectId else {
                throw PersistenceError.unsynchronizedMeasurement(identifier: measurement.identifier)
            }

            guard let measurementMO = try context.existingObject(with: measurementObjectId) as? MeasurementMO else {
                throw PersistenceError.measurementNotLoadable(measurement.identifier)
            }

            let accelerationsFile = SensorValueFile(fileType: SensorValueFileType.accelerationValueType)
            _ = try accelerationsFile.write(serializable: accelerations, to: measurement.identifier)
            let rotationsFile = SensorValueFile(fileType: SensorValueFileType.rotationValueType)
            _ = try rotationsFile.write(serializable: rotations, to: measurement.identifier)
            let directionsFile = SensorValueFile(fileType: SensorValueFileType.directionValueType)
            _ = try directionsFile.write(serializable: directions, to: measurement.identifier)

            measurementMO.accelerationsCount = measurementMO.accelerationsCount.advanced(by: accelerations.count)
            measurement.accelerationsCount = measurementMO.accelerationsCount
            measurementMO.rotationsCount = measurementMO.rotationsCount.advanced(by: rotations.count)
            measurement.rotationsCount = measurementMO.rotationsCount
            measurementMO.directionsCount = measurementMO.directionsCount.advanced(by: directions.count)
            measurement.directionsCount = measurementMO.directionsCount

            try context.save()
        }
    }

    public func save(measurement: Measurement) throws -> Measurement {
        try manager.wrapInContextReturn { context in
            guard let objectId = measurement.objectId else {
                throw PersistenceError.unsynchronizedMeasurement(identifier: measurement.identifier)
            }

            guard let managedObjectMeasurement = try context.existingObject(with: objectId) as? MeasurementMO else {
                throw PersistenceError.dataNotLoadable(measurement: measurement.identifier)
            }

            return try Measurement(managedObject: managedObjectMeasurement)
        }
    }

    // MARK: - Database Read Only Methods
    /**
     Loads the data belonging to the provided `measurement` in the background an calls `onFinishedCall` with the data storage representation of that `measurement`. Using that represenation is not thread safe. Do not use it outside of the handler.

     - Parameter measurementIdentifiedBy: The device wide unique identifier of the measurement to load.
     - Returns: The requested measurement as a model object.
     - Throws: `PersistenceError.measurementNotLoadable`, Some unspecified errors from within CoreData.
     */
    public func load(measurementIdentifiedBy identifier: Int64) throws -> Measurement {
        return try manager.wrapInContextReturn { context in
            do {
                guard let unwrappedMeasurement = try self.load(measurementIdentifiedBy: identifier, from: context) else {
                    throw PersistenceError.measurementNotLoadable(identifier)
                }
                return try Measurement(managedObject: unwrappedMeasurement)
            } catch {
                throw PersistenceError.measurementNotLoadable(identifier)
            }
        }
    }

    /**
     Loads all the measurements from the data storage.

     - Returns: An array of all measurements currently stored on this device.
     - Throws: Some unspecified errors from within CoreData.
     */
    public func loadMeasurements() throws -> [Measurement] {
        return try manager.wrapInContextReturn { context in
            let request = MeasurementMO.fetchRequest()
            var ret = [Measurement]()
            for fetchResult in try context.fetch(request) {
                let measurement = try Measurement(managedObject: fetchResult)
                ret.append(measurement)
            }
            return ret
        }
    }

    /**
     Provides only the valid locations within a cleaned geo location track. This excludes locations occuring because of geo location jitter and pauses.

     - Parameter track: The track to load a cleaned track for.
     - Returns: The cleaned list of geo locations from that track.
     - Throws: Some unspecified error from within CoreData.
     */
    public func loadClean(track: inout Track) throws -> [GeoLocation] {
        return try manager.wrapInContextReturn { context in
            let request = GeoLocationMO.fetchRequest()
            guard let parentObjectId = track.objectId else {
                throw PersistenceError.inconsistentState
            }
            request.predicate = NSPredicate(format: "track==%@ AND isPartOfCleanedTrack==%@", parentObjectId, NSNumber(value: true))
            request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
            request.resultType = .managedObjectResultType

            var ret = [GeoLocation]()
            for fetchResult in try context.fetch(request) {
                let location = try GeoLocation(managedObject: fetchResult, parent: &track)
                ret.append(location)
            }
            return ret
        }
    }

    /**
     Loads only those measurements that have not been synchronized to a Cyface database yet and that are synchronizable at the moment.

     - Returns: An array containing all the not synchronized measurements.
     - Throws: Some unspecified errors from within CoreData.
     */
    public func loadSynchronizableMeasurements() throws -> [Measurement] {
        return try manager.wrapInContextReturn { context in
            let request: NSFetchRequest<MeasurementMO> = MeasurementMO.fetchRequest()
            // Fetch only not synchronized measurements
            request.predicate = NSPredicate(format: "synchronized == %@ AND synchronizable == %@",
                                        argumentArray: [ NSNumber(value: false), NSNumber(value: true)])

            var ret = [Measurement]()
            for fetchResult in try context.fetch(request) {
                let measurement = try Measurement(managedObject: fetchResult)
                ret.append(measurement)
            }
            return ret
        }
    }

    /**
     Retrieves the list of all events of a certain `EventType` belonging to a `MeasurementMO` from the database.

     - Parameter typed: The `EventType` to load the `Event` objects for.
     - Parameter forMeasurement: The `MeasurementMO` object the loaded `Event` objects belong to.
     - Throws: Some unspecified error from within CoreData.
     */
    public func loadEvents(typed type: EventType, forMeasurement measurement: Measurement) throws -> [Event] {
        return try manager.wrapInContextReturn { context in
            guard let measurementObjectId = measurement.objectId else {
                throw PersistenceError.inconsistentState
            }

            let measurementMO = try context.existingObject(with: measurementObjectId)
            let request: NSFetchRequest = EventMO.fetchRequest()
            request.predicate = NSPredicate(format: "type == %@ AND measurement == %@", type.rawValue, measurementMO)
            request.sortDescriptors = [NSSortDescriptor(key: "time", ascending: true)]

            var ret = [Event]()
            for fetchResult in try context.fetch(request) {
                let event = Event(managedObject: fetchResult, parent: measurement)
                ret.append(event)
            }
            return ret
        }
    }

    /**
     Counts the amount of measurements currently stored in the data store.

     - Returns: The count of measurements currently stored on this device.
     - Throws: Some unspecified errors from within CoreData.
     */
    public func countMeasurements() throws -> Int {
        try manager.wrapInContextReturn { context in
            let request = MeasurementMO.fetchRequest()
            return try context.count(for: request)
        }
    }

    /**
     Counts the number of geo locations from a certain measurement.

     - Parameter measurement: The measurement to count the geo locations for
     - Returns: The count of locations measured in the measurement
     - Throws: Some unspecified errors from within CoreData.
     */
    public func countGeoLocations(forMeasurement measurement: Measurement) throws -> Int {
        try manager.wrapInContextReturn { context in
            guard let measurementObjectId = measurement.objectId else {
                throw PersistenceError.inconsistentState
            }

            let locationRequest = GeoLocationMO.fetchRequest()
            locationRequest.predicate = NSPredicate(format: "track.measurement = %@", measurementObjectId)

            return try context.count(for: locationRequest)
        }
    }

    /// The next identifier to assign to a new `Measurement`.
    /// - Throws: `PersistenceError.inconsistentState`
    private func nextIdentifier() throws -> Int64 {
        let persistentStore = manager.persistentContainer.persistentStoreCoordinator.persistentStores[0]
        let coordinator = manager.persistentContainer.persistentStoreCoordinator

        if lastIdentifier == nil {
            // identifier is already stored as metadata.
            if let currentIdentifier = coordinator.metadata(for: persistentStore)["de.cyface.mid"] as? Int64 {
                lastIdentifier = currentIdentifier
                // identifier is not yet stored, create an entry
            } else {
                lastIdentifier = Int64(0)
                coordinator.setMetadata(["de.cyface.mid": lastIdentifier as Any], for: persistentStore)
            }
        }

        guard let lastIdentifier = lastIdentifier else {
            throw PersistenceError.inconsistentState
        }

        let nextIdentifier = lastIdentifier + 1
        self.lastIdentifier = nextIdentifier
        coordinator.setMetadata(["de.cyface.mid": nextIdentifier], for: persistentStore)
        return nextIdentifier
    }

    /**
     Internal load method, loading the provided `measurement` on the provided `context`.

     - Parameters:
        - measurementIdentifiedBy: The `measurement` to load.
        - from: The CoreData `context` to load the `measurement` from.
     - Returns: The `MeasurementMO` object for the provided identifier or `nil` if no such mesurement exists.
     - Throws: Some unspecified errors from within CoreData.
     */
    private func load(measurementIdentifiedBy identifier: Int64, from context: NSManagedObjectContext) throws -> MeasurementMO? {
        let fetchRequest = MeasurementMO.fetchRequest()
        // The following needs to use an Objective-C number. That is why `measurementIdentifier` is wrapped in `NSNumber`
        fetchRequest.predicate = NSPredicate(format: "identifier==%@", NSNumber(value: identifier))
        // fetchRequest.relationshipKeyPathsForPrefetching = ["tracks.locations"]

        let results = try context.fetch(fetchRequest)
        if results.count == 1 {
            return results[0]
        } else {
            return nil
        }
    }

    // MARK: - Support Methods

    /**
     Collects all geo locations from all tracks of a measurement and merges them to a single array.

     - Parameter from: The measurement to collect the geo locations from.
     - Returns: An array containing all the collected geo locations from all tracks of the provided measurement.
     - Throws: `SerializationError.missingData`, `SerializationError.invalidData`.
     */
    public static func collectGeoLocations(from measurement: Measurement) throws -> [GeoLocation] {
        var ret = [GeoLocation]()

        for track in measurement.tracks {
            ret.append(contentsOf: track.locations)
        }

        return ret
    }

    /**
     Transforms a list of `MeasurementMO` objects to a list containing the identifiers.

     If you want to use a list of `MeasurementMO` objects between different threads you must reload them on a context appropriate for that thread.
     To ease this task, this method can be used to make a collection of measurement identifiers, transfer them to the other thread and reload all the measurements there.

     - Parameter from: The array of `MeasurementMO` instances to extract the identifiers for.
     - Returns: A collection containing all the device wide unqiue identifiers of the provided measurements.
     */
    public static func extractIdentifiers(from measurements: [Measurement]) -> [Int64] {
        var ret = [Int64]()
        for measurement in measurements {
            ret.append(measurement.identifier)
        }
        return ret
    }

    /**
     Traverses all tracks captured as part of a measurement and provides each track and geo location to a callback.

     - Parameters:
        - ofMeasurement: The measurement to traverse the tracks for
        - call: A callback function receiving the track and geo location pairs
     */
    public static func traverseTracks(ofMeasurement measurement: Measurement, call closure: (Track, GeoLocation) -> Void) {
        for track in measurement.tracks {
            track.locations.forEach { location in closure(track, location) }
        }
    }

    /**
     A structure for all the errors thrown by the `PersistenceLayer`.

     - Author: Klemens Muthmann
     - Version: 3.0.0
     - Since: 2.3.0
     */
    enum PersistenceError: Error {
        /// If a measurement was not loaded successfully.
        case measurementNotLoadable(Int64)
        /// If measurements could not be loaded in bulk.
        case measurementsNotLoadable
        /// If some data belonging to a measurement could not be loaded.
        case dataNotLoadable(measurement: Int64)
        /// If it is impossible to load the last generated identifier. This can only happen if the system settings have been tempered with.
        case inconsistentState
        case unsynchronizedMeasurement(identifier: Int64)
    }
}
