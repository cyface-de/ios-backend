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
 An instance of an object of this class is a wrapper around the CoreData data storage used by the capturing service. It allows CRUD operations on measurements, geo locations and sensor values.
 
 - Author: Klemens Muthmann
 - Version:7.0.0
 - Since: 1.0.0
 - throws: Most methods implemented by this class throw internal CoreData errors. This usually indicates something to be seriously wrong with the device executing the method and are almost never recoverable. Errors from the file system are rethrown on reading and writing sensor values. Those are mostly not recoverable as well. Another common error is an inconstent state of the measurement worked on, such as locations with non strongly monotonically increasing timestamps.
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
     - Throws: `PersistenceError.inconsistentState`
     */
    func createMeasurement(at timestamp: UInt64, inMode mode: String) throws -> Measurement {
        return try manager.wrapInContextReturn { context in
            // This checks if a measurement with that identifier already exists and generates a new identifier until it finds one with no corresponding measurement. This is required to handle legacy data and installations, that still have measurements with falsely generated data.
            var identifier = try nextIdentifier()
            while try load(measurementIdentifiedBy: identifier, from: context) != nil {
                identifier = try nextIdentifier()
            }

            let measurementMO = MeasurementMO(context: context)
            measurementMO.timestamp = Int64(timestamp)
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
    public func createEvent(of type: EventType, withValue: String? = nil, timestamp: Date = Date(), parent: inout Measurement) throws -> Event {
        return try manager.wrapInContextReturn { context in
            let eventMO = EventMO(context: context)
            eventMO.typeEnum = type
            eventMO.time = timestamp as NSDate
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
        - measurement: The identifier of the measurement to delete from the data storage.
     - Throws: `PersistenceError.measurementNotLoadable`
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
     
     - Parameter measurement: The identifier of the measurement to strip of accelerations.
     - Throws: `PersistenceError.measurementNotLoadable`
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
        os_log("Storing %{PUBLIC}d locations to measurement %{PUBLIC}d!", log: PersistenceLayer.log, type: .debug, locations.count, measurement.identifier)
        try manager.wrapInContext { context in

            guard let measurementMO = try load(measurementIdentifiedBy: measurement.identifier, from: context) else {
                throw PersistenceError.measurementNotLoadable(measurement.identifier)
            }

            guard let track = measurement.tracks.last else {
                throw PersistenceError.inconsistentState
            }
            guard let trackObjectId = track.objectId else {
                throw PersistenceError.nonPersistentTrackEncountered(track, measurement)
            }

            let geoLocationFetchRequest = GeoLocationMO.fetchRequest()
            geoLocationFetchRequest.fetchLimit = 1
            let maxTimestampInTrackPredicate = NSPredicate(format: "track==%@ AND isPartOfCleanedTrack==%@", trackObjectId, NSNumber(value: true))
            geoLocationFetchRequest.predicate = maxTimestampInTrackPredicate
            geoLocationFetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            geoLocationFetchRequest.resultType = .managedObjectResultType
            let capturedLocations = try context.fetch(geoLocationFetchRequest)
            var lastCapturedLocation = capturedLocations.first
            var distance = 0.0

            guard let dbTrack = try context.existingObject(with: trackObjectId) as? TrackMO else {
                throw PersistenceError.trackNotLoadable(track, measurement)
            }

            try locations.forEach { location in
                var geoLocation = GeoLocation(
                    latitude: location.latitude,
                    longitude: location.longitude,
                    accuracy: location.accuracy,
                    speed: location.speed,
                    timestamp: UInt64(location.timestamp.timeIntervalSince1970 * 1000.0),
                    isValid: location.isValid,
                    parent: track)
                try track.append(location: geoLocation)
                let dbLocation = try GeoLocationMO(location: &geoLocation, context: context)
                dbTrack.addToLocations(dbLocation)

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

            os_log("Stored %{PUBLIC}d locations to measurement %{PUBLIC}d with calculated length of %{PUBLIC}f!",
                           log: PersistenceLayer.log,
                           type: .debug,
                           locations.count,
                           measurement.identifier,
                           measurement.trackLength)
        }
    }

    /**
     Stores the provided `SensorValue`-objects to the provided measurement. The default value for each array is an empty array. This allows to store only one type of `SensorValue`.

     - Parameters:
        - accelerations: An array of acceleration `SensorValue` instances to store.
        - rotations: An array of rotation `SensorValue` instances to store.
        - directions: An array of direction `SensorValue` instances to store.
        - in: The measurement to store the `accelerations` to.
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
            let rotationsFile = SensorValueFile(fileType: SensorValueFileType.rotationValueType)
            let directionsFile = SensorValueFile(fileType: SensorValueFileType.directionValueType)
            if !accelerations.isEmpty {
                do {
                    _ = try accelerationsFile.write(serializable: accelerations, to: measurement.identifier)
                } catch {
                    debugPrint("Unable to write data to file \(accelerationsFile.fileName)!")
                    throw error
                }
            }

            if !rotations.isEmpty {
                do {
                    _ = try rotationsFile.write(serializable: rotations, to: measurement.identifier)
                } catch {
                    debugPrint("Unable to write data to file \(rotationsFile.fileName)!")
                    throw error
                }
            }

            if !directions.isEmpty {
                do {
                    _ = try directionsFile.write(serializable: directions, to: measurement.identifier)
                } catch {
                    debugPrint("Unable to write data to file \(directionsFile.fileName)!")
                    throw error
                }
            }

            // TODO: Remove all those counts from the data model. It is a lef over from the old data format. After removal, the data model needs to change and we need new migration code.
            measurement.accelerationsCount = measurement.accelerationsCount.advanced(by: accelerations.count)
            measurementMO.accelerationsCount = measurement.accelerationsCount
            measurement.rotationsCount = measurement.rotationsCount.advanced(by: rotations.count)
            measurementMO.rotationsCount = measurement.rotationsCount
            measurement.directionsCount = measurement.directionsCount.advanced(by: directions.count)
            measurementMO.directionsCount = measurement.directionsCount

            try context.save()
        }
    }

    /// Save the provided `Measurement` via CoreData
    public func save(measurement: Measurement) throws -> Measurement {
        try manager.wrapInContextReturn { context in
            if let objectId = measurement.objectId {
                guard let managedObjectMeasurement = try context.existingObject(with: objectId) as? MeasurementMO else {
                    throw PersistenceError.dataNotLoadable(measurement: measurement.identifier)
                }

                try managedObjectMeasurement.update(from: measurement)
                try context.save()

                return try Measurement(managedObject: managedObjectMeasurement)
            } else {
                let newManagedMeasurement = MeasurementMO(context: context)
                newManagedMeasurement.identifier = measurement.identifier
                newManagedMeasurement.timestamp = Int64(measurement.timestamp)
                measurement.objectId = newManagedMeasurement.objectID
                try newManagedMeasurement.update(from: measurement)

                try context.save()

                return try Measurement(managedObject: newManagedMeasurement)
            }
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
                let location = GeoLocation(managedObject: fetchResult, parent: track)
                ret.append(location)
            }
            return ret
        }
    }

    /**
     Loads only those measurements that have not been synchronized to a Cyface database yet and that are synchronizable at the moment.

     - Returns: An array containing all the not synchronized measurements.
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
     */
    public func loadEvents(typed type: EventType, forMeasurement measurement: Measurement) throws -> [Event] {
        return try manager.wrapInContextReturn { context in
            guard let measurementObjectId = measurement.objectId else {
                throw PersistenceError.inconsistentState
            }

            let request: NSFetchRequest = EventMO.fetchRequest()
            let typePredicate = NSPredicate(format: "type == %d", type.rawValue)
            let parentPredicate = NSPredicate(format: "measurement == %@", measurementObjectId)
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [typePredicate, parentPredicate])
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
    func nextIdentifier() throws -> Int64 {
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
     */
    public static func collectGeoLocations(from measurement: Measurement) -> [GeoLocation] {
        var ret = [GeoLocation]()

        for track in measurement.tracks {
            ret.append(contentsOf: track.locations)
        }

        return ret
    }

    /**
     Transforms a list of `Measurement` objects to a list containing the identifiers.

     If you want to use a list of `Measurement` objects between different threads you must reload them on a context appropriate for that thread.
     To ease this task, this method can be used to make a collection of measurement identifiers, transfer them to the other thread and reload all the measurements there.

     - Parameter from: The array of `Measurement` instances to extract the identifiers for.
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
        - call: A callback function receiving the track and geo location pairs.
     */
    public static func traverseTracks(ofMeasurement measurement: Measurement, call closure: (Track, GeoLocation) -> Void) {
        for track in measurement.tracks {
            track.locations.forEach { location in closure(track, location) }
        }
    }
}

/**
 A structure for all the errors thrown by the `PersistenceLayer`.

 - Author: Klemens Muthmann
 - Version: 3.1.0
 - Since: 2.3.0
 */
public enum PersistenceError: Error {
    /// If a measurement was not loaded successfully.
    case measurementNotLoadable(Int64)
    /// If a track from a measurement could not be loaded
    case trackNotLoadable(Track, Measurement)
    /// If a track was not persistent (i.e. had not valid objectId) at a place where only persistent tracks are valid
    case nonPersistentTrackEncountered(Track, Measurement)
    /// If measurements could not be loaded in bulk.
    case measurementsNotLoadable
    /// If some data belonging to a measurement could not be loaded.
    case dataNotLoadable(measurement: Int64)
    /// If it is impossible to load the last generated identifier. This can only happen if the system settings have been tempered with.
    case inconsistentState
    /// On trying to load a not yet synchronized `Measurement`. This is usually a `Measurement` with en `objectId` of `nil`.
    case unsynchronizedMeasurement(identifier: Int64)
}

extension PersistenceError: LocalizedError {
    // Localized error description, with further information about the error.
    public var errorDescription: String? {
        switch self {
        case .measurementNotLoadable(let measurementIdentifier):
            let errorMessage = NSLocalizedString("de.cyface.error.PersistenceError.measurementNotLoadable",
                                                 value: "Unable to load measurement %d!",
                                                 comment: """
                Tell the user that a measurement was not loaded successfully. \
                The first parameter is the identifier of the measurement.
                """)
            return String.localizedStringWithFormat(errorMessage, measurementIdentifier)
        case .trackNotLoadable(_, let measurement):
            let errorMessage = NSLocalizedString("de.cyface.error.PersistenceError.trackNotLoadable",
                                                 value: "Unable to load track from measurement %d!",
                                                 comment: """
                Tell the user that the system was unable to load a track from a measurement. \
                The first parameter is the measurement the track belongs to.
                """)
            return String.localizedStringWithFormat(errorMessage, measurement.identifier)
        case .nonPersistentTrackEncountered(_, let measurement):
            let errorMessage = NSLocalizedString("de.cyface.error.PersistenceError.nonPersistentTrackEncountered",
                                                 value: "Unable to update values of non persistent track from measurement %d!",
                                                 comment: """
                Tell the user that the system was unable to update a track, since that track was not yet saved, \
                to the database. The first parameter is the identifier of the measurement the track belongs to.
                """)
            return String.localizedStringWithFormat(errorMessage, measurement.identifier)
        case .dataNotLoadable(measurement: let measurementIdentifier):
            let errorMessage = NSLocalizedString("de.cyface.error.PersistenceError.dataNotLoadable",
                                                 value: "Unable to load some data belonging to measurement %d!",
                                                 comment: """
                Tell the user that the system was unable to load data belonging to some measurement. \
                The first parameter is the identifier of the measurement!
                """)
            return String.localizedStringWithFormat(errorMessage, measurementIdentifier)
        case .inconsistentState:
            let errorMessage = NSLocalizedString("de.cyface.error.PersistenceError.inconsistentState",
                                                 value: "Data storage is in an inconsistent state!",
                                                 comment: """
                Tell the user that the data storage was in an inconsistent state and could not be accessed!
                """)
            return String.localizedStringWithFormat(errorMessage)
        case .unsynchronizedMeasurement(identifier: let measurementIdentifier):
            let errorMessage = NSLocalizedString("de.cyface.error.PersistenceError.unsynchronizedMeasurement",
                                                 value: "Failed to load measurement %d since it was not yet synchronized with the data storage!", comment: """
                Tell the user that the measurement that was supposed to be loaded was not yet saved!
                """)
            return String.localizedStringWithFormat(errorMessage, measurementIdentifier)
        case .measurementsNotLoadable:
            let errorMessage = NSLocalizedString("de.cyface.error.PersistenceError.measurementsNotLoadable",
                                                 value: "Multiple measurements from the data storage have not been loadable!",
                                                 comment: """
                Tell the user that measurements from the database are not loadable. \
                The reason is unknown at this point.
                """)
            return String.localizedStringWithFormat(errorMessage)
        }
    }
}
