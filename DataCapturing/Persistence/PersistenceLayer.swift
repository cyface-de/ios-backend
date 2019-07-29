/*
 * Copyright 2017 Cyface GmbH
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
 - Version: 5.2.0
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

    /// The next identifier to assign to a new `Measurement`.
    var nextIdentifier: Int64 {
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
            fatalError("No identifier available!")
        }

        let nextIdentifier = lastIdentifier + 1
        self.lastIdentifier = nextIdentifier
        coordinator.setMetadata(["de.cyface.mid": nextIdentifier], for: persistentStore)
        return nextIdentifier
    }

    /// Used to update a measurements length, each time new locations are added.
    private let distanceCalculator: DistanceCalculationStrategy

    /// The current `NSManagedObjectContext` used by this persistence layer. This has to be reset if the layer is used on a different thread. If it is `nil` each method is going to use its own context, which can cause problems if model objects are used between those methods.
    public var context: NSManagedObjectContext?

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
        - withContext: The measurement context the new measurement is created in.
     - Returns: The newly created model object for the measurement.
     - Throws:
        - Some unspecified errors from within CoreData.
     */
    func createMeasurement(at timestamp: Int64, withContext mContext: MeasurementContext) throws -> MeasurementMO {
        let context = getContext()
        // This checks if a measurement with that identifier already exists and generates a new identifier until it finds one with no corresponding measurement. This is required to handle legacy data and installations, that still have measurements with falsely generated data.
        var identifier = self.nextIdentifier
        while try load(measurementIdentifiedBy: identifier, from: context) != nil {
            identifier = self.nextIdentifier
        }

        if let description = NSEntityDescription.entity(forEntityName: "Measurement", in: context) {
            let measurement = MeasurementMO(entity: description, insertInto: context)
            measurement.timestamp = timestamp
            measurement.identifier = identifier
            measurement.synchronized = false
            measurement.synchronizable = false
            measurement.context = mContext.rawValue
            context.saveRecursively()

            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            context.refresh(measurement, mergeChanges: true)
            return measurement
        } else {
            fatalError("Unable to create new measurement. Something is seriously wrong with your CoreData configuration.")
        }
    }

    /**
     This adds a new track to the end of the list of tracks of the provided measurement. New locations are always written to the last track. You need to call this method before adding any locations to a measurement.

     - Parameter to: The measurement to add the new track to.
     */
    func appendNewTrack(to measurement: MeasurementMO) {
        let context = getContext()
        let measurementOnCurrentContext = migrate(measurement: measurement, to: context)
        if let trackDescription = NSEntityDescription.entity(forEntityName: "Track", in: context) {
            let track = Track.init(entity: trackDescription, insertInto: context)
            measurementOnCurrentContext.addToTracks(track)

            context.saveRecursively()
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            context.refresh(measurement, mergeChanges: true)
        } else {
            fatalError("Unable to create Track. Something is seriously wrong with your CoreData configuration.")
        }
    }

    /**
     Creates a new `Event` at the current time.

     - Parameter of: The type of the logged `Event`.
     */
    func createEvent(of type: EventType) -> Event {
        let context = getContext()
        let event = Event.init(context: context)
        event.typeEnum = type
        event.time = NSDate(timeIntervalSince1970: Double(DataCapturingService.currentTimeInMillisSince1970()) / 1000.0)

        return event
    }

    /**
     Deletes the measurement from the data storag.
     
     - Parameters:
        - measurement: The measurement to delete from the data storage.
     - Throws:
        - `PersistenceError` If the measurement to delete was not available.
        - Some unspecified errors from within CoreData.
        - Some internal file system error on failure of creating or accessing the accelerations file at the required path.
     */
    public func delete(measurement: MeasurementEntity) throws {
        let context = getContext()
        let measurementIdentifier = measurement.identifier
        guard let measurement = try load(measurementIdentifiedBy: measurement.identifier, from: context) else {
            throw PersistenceError(type: .measurementNotLoadable(measurementIdentifier), verboseDescription: "Unable to load measurement \(measurementIdentifier) from context \(context.name ?? "no name")!", inMethodName: #function, inFileName: #file, atLineNumber: #line)
        }

        let accelerationFile = AccelerationsFile()
        try accelerationFile.remove(from: measurement)
        context.delete(measurement)
        context.saveRecursively()
    }

    /**
     Deletes everything from the data storage.
     
     - Throws:
        - Some unspecified errors from within CoreData.
        - Some internal file system error on failure of creating the file at the required path.
     */
    func delete() throws {
        let context = getContext()
        let measurements = try loadMeasurements()
        let accelerationsFile = AccelerationsFile()

        for measurement in measurements {
            try accelerationsFile.remove(from: measurement)
            let object = try context.existingObject(with: measurement.objectID)
            context.delete(object)
        }
        context.saveRecursively()
    }

    /**
     Strips the provided measurement of all accelerations.
     
     - Parameter measurement: The measurement to strip of accelerations
     - Throws:
        - `PersistenceError` If the measurement to clean was not available.
        - Some unspecified errors from within CoreData.
        - Some internal file system error on failure of creating or accessing the accelerations file at the required path.
     */
    func clean(measurement: MeasurementEntity) throws {
        let context = getContext()
        let measurementIdentifier = measurement.identifier
        guard let measurement = try load(measurementIdentifiedBy: measurementIdentifier, from: context) else {
            throw PersistenceError(type: .measurementNotLoadable(measurementIdentifier), verboseDescription: "Unable to load measurement \(measurementIdentifier) from context \(context.name ?? "no name")! Measurement does not exist!", inMethodName: #function, inFileName: #file, atLineNumber: #line)
        }

        measurement.synchronized = true
        measurement.accelerationsCount = 0
        let accelerationsFile = AccelerationsFile()
        try accelerationsFile.remove(from: measurement)

        context.saveRecursively()
    }

    /**
     Stores the provided `locations` to the most recent track in the measurement. Please make sure to call `appendNewTrack(:to)` with the same measurement at least once before using this method.

     - Parameters:
     - locations: An array of `GeoLocation` instances, ordered by timestamp to store in the database.
     - in: The measurement to store the `location` and `accelerations` to.
     - Throws:
        - `PersistenceError` If no valid `Track` was available.
        - Some unspecified errors from within CoreData.
     */
    func save(locations: [GeoLocation], in measurement: MeasurementMO) throws {
        let context = getContext()
        guard let locationDescription = NSEntityDescription.entity(forEntityName: "GeoLocation", in: context) else {
            fatalError("Unable to create geo location description on context \(context.name ?? "no name")!")
        }

        let measurement = migrate(measurement: measurement, to: context)

        guard let track = measurement.tracks?.lastObject as? Track else {
            throw PersistenceError(type: .dataNotLoadable(measurement: measurement.identifier), verboseDescription: "Unable to load any track for measurement \(measurement.identifier)! Did you create a track before saving locations?", inMethodName: #function, inFileName: #file, atLineNumber: #line)
        }

        let geoLocationFetchRequest: NSFetchRequest<GeoLocationMO> = GeoLocationMO.fetchRequest()
        geoLocationFetchRequest.fetchLimit = 1
        let maxTimestampInTrackPredicate = NSPredicate(format: "track==%@ AND isPartOfCleanedTrack==%@", track, NSNumber(value: true))
        geoLocationFetchRequest.predicate = maxTimestampInTrackPredicate
        geoLocationFetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        geoLocationFetchRequest.resultType = .managedObjectResultType
        let capturedLocations = try context.fetch(geoLocationFetchRequest)
        var lastCapturedLocation = capturedLocations.first
        var distance = 0.0

        locations.forEach { location in
            let dbLocation = GeoLocationMO.init(entity: locationDescription, insertInto: context)
            dbLocation.lat = location.latitude
            dbLocation.lon = location.longitude
            dbLocation.speed = location.speed
            dbLocation.timestamp = location.timestamp
            dbLocation.accuracy = location.accuracy
            dbLocation.isPartOfCleanedTrack = location.isValid
            track.addToLocations(dbLocation)

            if dbLocation.isPartOfCleanedTrack {
                if let lastCapturedLocation = lastCapturedLocation {
                    let delta = self.distanceCalculator.calculateDistance(from: lastCapturedLocation, to: dbLocation)
                    distance += delta
                }
            lastCapturedLocation = dbLocation
            }
        }

        measurement.trackLength += distance

        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        context.saveRecursively()
        context.refresh(measurement, mergeChanges: true)
    }

    /**
     Stores the provided `accelerations` to the provided measurement.

     - Parameters:
     - accelerations: An array of `Acceleration` instances to store.
     - in: The measurement to store the `accelerations` to.
     - Throws:
        - Some internal file system error on failure of accessing the acceleration file at the required path.
     */
    func save(accelerations: [Acceleration], in measurement: MeasurementMO) throws {
        let context = getContext()

        let measurement = migrate(measurement: measurement, to: context)

        let accelerationsFile = AccelerationsFile()
        _ = try accelerationsFile.write(serializable: accelerations, to: measurement.identifier)
        measurement.accelerationsCount = measurement.accelerationsCount.advanced(by: accelerations.count)

        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        context.saveRecursively()
        context.refresh(measurement, mergeChanges: true)
    }

    // MARK: - Database Read Only Methods
    /**
     Internal load method, loading the provided `measurement` on the provided `context`.

     - Parameters:
        - measurementIdentifiedBy: The `measurement` to load.
        - from: The CoreData `context` to load the `measurement` from.
     - Returns: The `MeasurementMO` object for the provided identifier or `nil` if no such mesurement exists.
     - Throws:
        - Some unspecified errors from within CoreData.
     */
    private func load(measurementIdentifiedBy identifier: Int64, from context: NSManagedObjectContext) throws -> MeasurementMO? {
        let fetchRequest: NSFetchRequest<MeasurementMO> = MeasurementMO.fetchRequest()
        // The following needs to use an Objective-C number. That is why `measurementIdentifier` is wrapped in `NSNumber`
        fetchRequest.predicate = NSPredicate(format: "identifier==%@", NSNumber(value: identifier))
        //fetchRequest.relationshipKeyPathsForPrefetching = ["tracks.locations"]

        let results = try context.fetch(fetchRequest)
        if results.count == 1 {
            return results[0]
        } else {
            return nil
        }
    }

    /**
     Loads the data belonging to the provided `measurement` in the background an calls `onFinishedCall` with the data storage representation of that `measurement`. Using that represenation is not thread safe. Do not use it outside of the handler.

     - Parameter measurementIdentifiedBy: The device wide unique identifier of the measurement to load.
     - Returns: The requested measurement as a model object.
     - Throws:
        - `PersistenceError` If there is no such measurement.
        - Some unspecified errors from within CoreData.
     */
    public func load(measurementIdentifiedBy identifier: Int64) throws -> MeasurementMO {
        let context = getContext()
        context.automaticallyMergesChangesFromParent = true
        if let measurement = try self.load(measurementIdentifiedBy: identifier, from: context) {
            return measurement
        } else {
            throw PersistenceError(type: .measurementNotLoadable(identifier), verboseDescription: "Unable to load measurement \(identifier) from context \(context.name ?? "no name")! No such measurement!", inMethodName: #function, inFileName: #file, atLineNumber: #line)
        }
    }

    /**
     Loads all the measurements from the data storage.

     - Returns: An array of all measurements currently stored on this device.
     - Throws:
        - Some unspecified errors from within CoreData.
     */
    public func loadMeasurements() throws -> [MeasurementMO] {
        let context = getContext()
        let request: NSFetchRequest<MeasurementMO> = MeasurementMO.fetchRequest()
        let fetchResult = try context.fetch(request)
        return fetchResult
    }

    /**
     Provides only the valid locations within a cleaned geo location track. This excludes locations occuring because of geo location jitter and pauses.

     - Parameter track: The track to load a cleaned track for
     - Returns: The cleaned list of geo locations from that track
     - Throws:
        - Some unspecified error from within CoreData
     */
    public func loadClean(track: Track) throws -> [GeoLocationMO] {
        let context = getContext()
        let request: NSFetchRequest<GeoLocationMO> = GeoLocationMO.fetchRequest()
        request.predicate = NSPredicate(format: "track==%@ AND isPartOfCleanedTrack==%@", track, NSNumber(value: true))
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        request.resultType = .managedObjectResultType
        let fetchResult = try context.fetch(request)
        return fetchResult
    }

    /**
     Loads only those measurements that have not been synchronized to a Cyface database yet and that are synchronizable at the moment.

     - Returns: An array containing all the not synchronized measurements.
     - Throws:
        - Some unspecified errors from within CoreData.
     */
    public func loadSynchronizableMeasurements() throws -> [MeasurementMO] {
        let context = getContext()
        let request: NSFetchRequest<MeasurementMO> = MeasurementMO.fetchRequest()
        // Fetch only not synchronized measurements
        request.predicate = NSPredicate(format: "synchronized == %@ AND synchronizable == %@", argumentArray: [ NSNumber(value: false), NSNumber(value: true)])
        let fetchResult = try context.fetch(request)
        return fetchResult
    }

    /**
     Counts the amount of measurements currently stored in the data store.

     - Returns: The count of measurements currently stored on this device.
     - Throws:
        - Some unspecified errors from within CoreData.
     */
    public func countMeasurements() throws -> Int {
        let context = getContext()
        let request: NSFetchRequest<MeasurementMO> = MeasurementMO.fetchRequest()
        let count = try context.count(for: request)
        return count
    }

    /**
     Migrates a `MeasurementMO` instance to a new `NSManagedObjectContext`. Calling this method is always required if there is a new context.

     - Parameters:
        - measurement: The `MeasurementMO` instance to migrate.
        - to: The `NSManagedObjectContext` to migrate to.
     - Returns: The migrated `MeasurementMO` instance.
     - Throws:
        - `PersistenceError.inconsistentData` If CoreData is incapable of migrating. If this happens something is seriously wrong with CoreData.
     */
    private func migrate(measurement: MeasurementMO, to context: NSManagedObjectContext) -> MeasurementMO {
        guard let migratedMeasurement = context.object(with: measurement.objectID) as? MeasurementMO else {
            fatalError("CoreData was unable to migrate measurement \(measurement) to context \(context.name ?? "no name")! Something seems to be seriously wrong with your CoreData configuration.")
        }

        return migratedMeasurement
    }

    /**
     Either provides the existing `NSManagedObjectContext` currently used by this instance or a temporary background context only valid for the current call.
     If a background context is used all model objects from previous calls become separated from CoreData and will not work anymore.

     - Returns: The current value stored in the `context` attribute or a temporary background context.
     */
    private func getContext() -> NSManagedObjectContext {
        guard let context = self.context == nil ? manager.backgroundContext : self.context else {
            fatalError("There has been no CoreData context and it was not possible to create a background context. Something seems to be seriously wrong with your CoreData configuration.")
        }

        return context
    }

    // MARK: - Support Methods

    /**
     Creates a new background `NSManagedObjectContext` for the current thread. This can be used to set an appropriate value for the `context` attribute.

     - Returns: The newly created context.
     */
    public func makeContext() -> NSManagedObjectContext {
        return manager.backgroundContext
    }

    /**
     Collects all geo locations from all tracks of a measurement and merges them to a single array.

     - Parameter from: The measurement to collect the geo locations from.
     - Returns: An array containing all the collected geo locations from all tracks of the provided measurement.
     - Throws:
        - `SerializationError.missingData` If no track data was found.
        - `SerializationError.invalidData` If the database provided inconsistent and wrongly typed data. Something is seriously wrong in these cases.
     */
    public static func collectGeoLocations(from measurement: MeasurementMO) throws -> [GeoLocationMO] {
        guard let tracks = measurement.tracks else {
            throw SerializationError.missingData
        }

        var ret = [GeoLocationMO]()

        for track in tracks {
            guard let typedTrack = track as? Track, let locations = typedTrack.locations else {
                throw SerializationError.invalidData
            }

            guard let typedLocations = locations.array as? [GeoLocationMO] else {
                throw SerializationError.invalidData
            }

            ret.append(contentsOf: typedLocations)
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
    public static func extractIdentifiers(from measurements: [MeasurementMO]) -> [Int64] {
        var ret = [Int64]()
        for measurement in measurements {
            ret.append(measurement.identifier)
        }
        return ret
    }
}

/**
 Adds functions to save a context and all parent contexts up to the `NSPersistentContainer`.
 */
extension NSManagedObjectContext {

    /**
     Saves this context and all parent contexts if there are changes.
     */
    func saveRecursively() {
        performAndWait {
            if self.hasChanges {
                self.saveThisAndParentContexts()
            }
        }
    }

    /**
     Saves this context and its parent.
     */
    func saveThisAndParentContexts() {
        do {
            try save()
            parent?.saveRecursively()
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
}

/**
 A structure for all the errors thrown by the `PersistenceLayer`.

 - Author: Klemens Muthmann
 - Version: 2.0.0
 - Since: 2.3.0
 */
struct PersistenceError: Error {
    /**
     Error categories thrown by the `PersistenceLayer`.

     ```
     case measurementNotLoadable
     case measurementsNotLoadable
     case dataNotLoadable
     ```

     - Author: Klemens Muthmann
     - Version: 1.0.0
     - Since: 4.0.0
     */
    enum Category {
        /// If a measurement was not loaded successfully.
        case measurementNotLoadable(Int64)
        /// If measurements could not be loaded in bulk.
        case measurementsNotLoadable
        /// If some data belonging to a measurement could not be loaded.
        case dataNotLoadable(measurement: Int64)
    }
    /// The `Category` of this error.
    let type: Category
    /// A human readable explanation for the error.
    let verboseDescription: String
    /// The name of the method this error has occured within.
    let inMethodName: String
    /// The name of the file this error has occured within.
    let inFileName: String
    /// The number of the line of code this error has occured within.
    let atLineNumber: Int

    /**
     Handles a `PersistenceError` appropriately, by showing its details.

     - Parameter error: The error to handle.
     - Returns: The error description shown by this method call.
     */
    static func handle(error: PersistenceError) -> String {
        let readableError = """
        \nERROR - operation: [\(error.type)];
        reason: [\(error.verboseDescription)];
        in method: [\(error.inMethodName)];
        in file: [\(error.inFileName)];
        at line: [\(error.atLineNumber)]\n
        """
        print(readableError)
        return readableError
    }
}
