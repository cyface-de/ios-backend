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

/**
 An instance of an object of this class is a wrapper around the CoreData data storage used by the capturing service. It allows CRUD operations on measurements, geo locations and accelerations. Most functions are asynchronous and provide a handler to react when they are finished.
 
 All entities have two representations. They are either represented as a subclass of `NSManagedObject` or as a custom entity class. The former are `MeasurementMO`, `AccelerationPointMO` and `GeoLocationMO`, while the latter are `MeasurementEntity`, `Acceleration` and `GeoLocation`. You should always try to the second costum classes, because the subclasses of `NSManagedObject` are not thread safe and should never be used outside of the handler they are provided to as parameter.
 
 Read access is public while manipulation of the data stored is restricted to the framework.
 
 - Author: Klemens Muthmann
 - Version: 2.0.0
 - Since: 1.0.0
 */
public class PersistenceLayer {

    // MARK: - Properties

    /// Container for the persistent object model.
    private let container: NSPersistentContainer

    /// The identifier that has been assigned the last to a new `Measurement`.
    var lastIdentifier: Int64?

    /// The next identifier to assign to a new `Measurement`.
    var nextIdentifier: Int64 {
        let persistentStore = container.persistentStoreCoordinator.persistentStores[0]
        let coordinator = container.persistentStoreCoordinator

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

    // MARK: - Initializers

    /**
     Public constructor usable by external callers.

     - Parameters:
     - withDistanceCalculator: An algorithm used to calculate the distance between geo locations.
     - onCompletionHandler: Called when the persistence layer has successfully finished initialization.
     - Throws: A `PersistenceError.modelNotLoabable` if the model is not loadable
     */
    public init(withDistanceCalculator: DistanceCalculationStrategy, onCompletionHandler: @escaping (PersistenceLayer?, Status) -> Void) throws {
        self.distanceCalculator = withDistanceCalculator
        /*
         The following code is necessary to load the CyfaceModel from the DataCapturing framework.
         It is only necessary because we are using a framework.
         Usually this would be much simpler as shown by many tutorials.
         Details are available from the following StackOverflow Thread:
         https://stackoverflow.com/questions/42553749/core-data-failed-to-load-model
         */
        let momdName = "CyfaceModel"

        let bundle = Bundle(for: type(of: self))
        guard let modelURL = bundle.url(forResource: momdName, withExtension: "momd") else {
            throw PersistenceError.modelNotLoadable(bundle.bundleURL)
        }

        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            throw PersistenceError.modelNotInitializable(modelURL)
        }

        container = NSPersistentContainer(name: momdName, managedObjectModel: mom)

        container.loadPersistentStores { _, error in
            if let error = error {
                onCompletionHandler(nil, .error(error))
            } else {
                onCompletionHandler(self, .success)
            }
        }
    }

    // MARK: - Database Writing Methods

    /**
     * Creates a new `measurement` asynchronuously and informs the caller when finished.
     *
     * - Parameters:
     *    - at: The time the measurement has been started at in milliseconds since the first of january 1970 (epoch).
     *    - withContext: The measurement context the new measurement is created in.
     *    - onFinishedCall: Handler that is called with the new measurement as parameter when the measurement has been stored in the database.
     */
    public func createMeasurement(at timestamp: Int64, withContext mContext: MeasurementContext, onFinishedCall handler: @escaping ((MeasurementMO?, Status) -> Void)) {
        container.performBackgroundTask { context in
            // This checks if a measurement with that identifier already exists and generates a new identifier until it finds one with no corresponding measurement. This is required to handle legacy data and installations, that still have measurements with falsely generated data.
            var identifier = self.nextIdentifier
            do {
                while try self.load(measurementIdentifiedBy: identifier, from: context) != nil {
                    identifier = self.nextIdentifier
                }

                if let description = NSEntityDescription.entity(forEntityName: "Measurement", in: context) {
                    let measurement = MeasurementMO(entity: description, insertInto: context)
                    measurement.timestamp = timestamp
                    measurement.identifier = identifier
                    measurement.synchronized = false
                    measurement.context = mContext.rawValue
                    context.saveRecursively()

                    handler(measurement, .success)
                } else {
                    handler(nil, .error(PersistenceError.measurementNotCreatable(timestamp)))
                }
            } catch let error {
                handler(nil, .error(error))
            }
        }
    }

    /**
     Deletes the measurement from the data storage on a background thread. Calls the provided handler when deletion has been completed.
     
     - Parameters:
     - measurement: The measurement to delete from the data storage.
     - onFinishedCall: The handler to call, when deletion has completed.
     */
    public func delete(measurement: MeasurementEntity, onFinishedCall handler: @escaping ((Status) -> Void)) {
        container.performBackgroundTask { context in
            let measurementIdentifier = measurement.identifier
            do {
                guard let measurement = try self.load(measurementIdentifiedBy: measurement.identifier, from: context) else {
                    handler(.error(PersistenceError.measurementNotLoadable(measurementIdentifier)))
                    return
                }

                let accelerationFile = AccelerationsFile()
                try accelerationFile.remove(from: measurement)
                context.delete(measurement)
                context.saveRecursively()
                handler(.success)
            } catch let error {
                handler(.error(error))
            }
        }
    }

    /**
     Deletes everything from the data storage.
     
     - Parameter onFinishedCall: A handler called after deletion is complete.
     */
    func delete(onFinishedCall handler: @escaping (Status) -> Void) {
        container.performBackgroundTask { context in
            self.loadMeasurements(onFinishedCall: { measurements, status in
                guard case .success = status else {
                    return handler(status)
                }
                do {
                    guard let measurements = measurements else {
                        return handler(.error(PersistenceError.measurementsNotLoadable))
                    }

                    for measurement in measurements {
                        let object = try context.existingObject(with: measurement.objectID)
                        context.delete(object)
                    }
                    context.saveRecursively()
                    handler(.success)
                } catch let error {
                    handler(.error(error))
                }
            })
        }
    }

    /**
     Strips the provided measurement of all accelerations.
     
     - Parameters:
     - measurement: The measurement to strip of accelerations
     */
    func clean(measurement: MeasurementEntity, whenFinishedCall finishedHandler: @escaping (Status) -> Void) {
        container.performBackgroundTask { context in
            do {
                let measurementIdentifier = measurement.identifier
                guard let measurement = try self.load(measurementIdentifiedBy: measurementIdentifier, from: context) else {
                    throw PersistenceError.dataNotLoadable(measurement: measurementIdentifier)
                }

                measurement.synchronized = true
                measurement.accelerationsCount = 0
                let accelerationsFile = AccelerationsFile()
                try accelerationsFile.remove(from: measurement)

                context.saveRecursively()
                finishedHandler(.success)
            } catch let error {
                finishedHandler(.error(error))
            }
        }
    }

    /**
     Stores the provided `location` and `accelerations` to the provided measurement.
     
     - Parameters:
     - locations: An array of `GeoLocation` instances to store.
     - toMeasurement: The measurement to store the `location` and `accelerations` to.
     - onFinished: The handler to call as soon as the database operation has finished.
     */
    func save(locations: [GeoLocation], toMeasurement measurement: MeasurementEntity, onFinished handler: @escaping (MeasurementMO?, Status) -> Void) {
        container.performBackgroundTask { context in
            let measurementIdentifier = measurement.identifier
            do {
                guard let measurement = try self.load(measurementIdentifiedBy: measurementIdentifier, from: context) else {
                    return handler(nil, .error(PersistenceError.measurementNotLoadable(measurementIdentifier)))
                }

                try self.internalSave(locations: locations, toMeasurement: measurement, onContext: context)
                context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                context.saveRecursively()
                context.refresh(measurement, mergeChanges: true)
                handler(measurement, .success)
            } catch let error {
                handler(nil, .error(error))
            }
        }
    }

    /**
     Saves the provided `GeoLocation` instances to the data storage. This is an internal save method that should only run on a `PersistenceContainer` background thread.

     This method also increases the track length based on the added `GeoLocation` objects.

     - Parameters:
     - locations: The `GeoLocation` instances to save.
     - toMeasurement: The measurement to save to.
     - onContext: The `NSManagedObjectContext` to save the data to.
     */
    private func internalSave(locations: [GeoLocation], toMeasurement measurement: MeasurementMO, onContext context: NSManagedObjectContext) throws {
        let geoLocationFetchRequest: NSFetchRequest<GeoLocationMO> = GeoLocationMO.fetchRequest()
        geoLocationFetchRequest.fetchLimit = 1
        let maxTimestampInMeaurementPredicate = NSPredicate(format: "timestamp==max(timestamp) && measurement==%@", measurement)
        geoLocationFetchRequest.predicate = maxTimestampInMeaurementPredicate
        var lastCapturedLocation = try geoLocationFetchRequest.execute().first
        var distance = 0.0

        locations.forEach { location in
            let dbLocation = GeoLocationMO.init(entity: GeoLocationMO.entity(), insertInto: context)
            dbLocation.lat = location.latitude
            dbLocation.lon = location.longitude
            dbLocation.speed = location.speed
            dbLocation.timestamp = location.timestamp
            dbLocation.accuracy = location.accuracy
            measurement.addToGeoLocations(dbLocation)

            if let lastCapturedLocation = lastCapturedLocation {
                let delta = distanceCalculator.calculateDistance(from: lastCapturedLocation, to: dbLocation)
                distance += delta
            }
            lastCapturedLocation = dbLocation
        }

        measurement.trackLength += distance
    }

    /**
     Stores the provided `location` and `accelerations` to the provided measurement.

     - Parameters:
     - accelerations: An array of `Acceleration` instances to store.
     - toMeasurement: The measurement to store the `location` and `accelerations` to.
     - onFinished: The handler to call as soon as the database operation has finished.
     - Throws: If accessing the local file system failes for some reason and thus the `Acceleration` instances can not be saved.
     */
    func save(accelerations: [Acceleration], toMeasurement measurement: MeasurementEntity, onFinished handler: @escaping ((MeasurementMO?, Status) -> Void)) {
        container.performBackgroundTask { context in
            do {
                let measurementIdentifier = measurement.identifier
                guard let measurement = try self.load(measurementIdentifiedBy: measurementIdentifier, from: context) else {
                    throw PersistenceError.dataNotLoadable(measurement: measurementIdentifier)
                }

                try self.internalSave(accelerations: accelerations, toMeasurement: measurement)
                measurement.accelerationsCount = measurement.accelerationsCount.advanced(by: accelerations.count)

                context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                context.saveRecursively()
                context.refresh(measurement, mergeChanges: true)
                handler(measurement, .success)
            } catch let error {
                handler(nil, .error(error))
            }
        }
    }

    /**
     Saves the provided `Acceleration` instances to the data storage. This is an internal save method that should only run on a `PersistenceContainer` background thread.

     - Parameters:
     - accelerations: The `GeoLocation` instances to save.
     - toMeasurement: The measurement to save to.
     - Throws: If accessing the local file system failes for some reason and thus the `Acceleration` instances can not be saved.
     */
    private func internalSave(accelerations: [Acceleration], toMeasurement measurement: MeasurementMO) throws {
        let accelerationsFile = AccelerationsFile()
        _ = try accelerationsFile.write(serializable: accelerations, to: measurement.identifier)
    }

    // MARK: - Database Read Only Methods
    /**
     Internal load method, loading the provided `measurement` on the provided `context`.
     
     - Parameters:
     - measurementIdentifiedBy: The `measurement` to load.
     - from: The CoreData `context` to load the `measurement` from.
     - Returns:
     - The `MeasurementMO` object for the provided identifier or `nil` if no such mesurement exists.
     */
    private func load(measurementIdentifiedBy identifier: Int64, from context: NSManagedObjectContext) throws -> MeasurementMO? {
        let fetchRequest: NSFetchRequest<MeasurementMO> = MeasurementMO.fetchRequest()
        // The following needs to use an Objective-C number. That is why `measurementIdentifier` is wrapped in `NSNumber`
        fetchRequest.predicate = NSPredicate(format: "identifier==%@", NSNumber(value: identifier))

        let results = try context.fetch(fetchRequest)
        if results.count == 1 {
            return results[0]
        } else {
            return nil
        }
    }

    /**
     Loads the data belonging to the provided `measurement` in the background an calls `onFinishedCall` with the data storage representation of that `measurement`. Using that represenation is not thread safe. Do not use it outside of the handler.
     
     - Parameters:
     - measurement: The `measurement` to load.
     - onFinishedCall: The handler to call when loading the `measurement` has finished
     */
    public func load(measurementIdentifiedBy identifier: Int64, onFinishedCall handler: @escaping (MeasurementMO?, Status) -> Void) {
        container.performBackgroundTask { context in
            context.automaticallyMergesChangesFromParent = true
            do {
                if let measurement = try self.load(measurementIdentifiedBy: identifier, from: context) {
                    handler(measurement, .success)
                } else {
                    handler(nil, .error(PersistenceError.dataNotLoadable(measurement: identifier)))
                }
            } catch let error {
                handler(nil, .error(error))
            }
        }
    }

    /**
     Loads all the measurements from the data storage. Runs asynchronously in the background and calls a handler after loading has been completed. You should never use the objects in the provided array outside of the handler, since they are not thread safe and lose all data if transfered outside.
     
     - Parameters:
     - handler: The handler to call after loading the measurements has finished.
     */
    public func loadMeasurements(onFinishedCall handler: @escaping ([MeasurementMO]?, Status) -> Void) {
        container.performBackgroundTask { (context) in
            let request: NSFetchRequest<MeasurementMO> = MeasurementMO.fetchRequest()
            do {
                let fetchResult = try context.fetch(request)
                handler(fetchResult, .success)
            } catch let error {
                handler(nil, .error(error))
            }
        }
    }

    /**
     Loads only those measurements that have not been synchronized to a Cyface database yet.

     - Parameter onFinishedCall: Handler called when loading the not synchronized measurements has finished. This provides the loaded measurements as an array, which will be empty if there are no such measurements.
     */
    public func loadSynchronizableMeasurements(onFinishedCall handler: @escaping ([MeasurementMO]?, Status) -> Void) {
        container.performBackgroundTask { (context) in
            let request: NSFetchRequest<MeasurementMO> = MeasurementMO.fetchRequest()
            // Fetch only not synchronized measurements
            request.predicate = NSPredicate(format: "synchronized == %@", NSNumber(value: false))
            do {
                let fetchResult = try context.fetch(request)
                handler(fetchResult, .success)
            } catch let error {
                handler(nil, .error(error))
            }
        }
    }

    /**
     Counts the amount of measurements currently stored in the data store, asynchronously in the background.
     
     - Parameter handler: The handler called after counting has finished. This handler receives the result as a parameter.
     */
    public func countMeasurements(onFinishedCall handler: @escaping (Int?, Status) -> Void) {
        container.performBackgroundTask { (context) in
            let request: NSFetchRequest<MeasurementMO> = MeasurementMO.fetchRequest()
            do {
                let count = try context.count(for: request)
                handler(count, .success)
            } catch let error {
                handler(nil, .error(error))
            }
        }
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
 An enumeration of all the errors thrown by the `PersistenceLayer`.

 ```
 case modelNotLoadable
 case modelNotInitializable
 case measurementNotCreatable
 case measurementNotLoadable
 case measurementsNotLoadable
 case dataNotLoadable
 ```

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 2.3.0
 */
enum PersistenceError: Error {
    /// If the CoreData model used by the Cyface SDK was not loadable
    case modelNotLoadable(URL)
    /// If the CoreData model used by the Cyface SDK was not initialized successfully.
    case modelNotInitializable(URL)
    /// If a measurement was not created successfully.
    case measurementNotCreatable(Int64)
    /// If a measurement was not loaded successfully.
    case measurementNotLoadable(Int64)
    /// If measurements could not be loaded in bulk.
    case measurementsNotLoadable
    /// If some data belonging to a measurement could not be loaded.
    case dataNotLoadable(measurement: Int64)
}
