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

    // MARK: - Initializers

    /**
     Public constructor usable by external callers.

     - Parameter onCompletionHandler: Called when the persistence layer has successfully finished initialization.
     */
    public init(onCompletionHandler: @escaping () -> Void) {
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
            fatalError("Error loading model from bundle \(bundle.bundleURL).")
        }

        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }

        container = NSPersistentContainer(name: momdName, managedObjectModel: mom)

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unable to load persistent storage \(error).")
            } else {
                onCompletionHandler()
            }
        }
    }

    // MARK: - Database Writing Methods

    /**
     * Creates a new measurement with the provided `timestamp`.
     *
     * - Parameters:
     *     - timestamp: The time the measurement has been started at in milliseconds since the first of january 1970 (epoch).
     *     - withContext: The measurement context the new measurement is created in.
     */
    @available(*, deprecated, message: "Please use the asynchronous version instead")
    public func createMeasurement(at timestamp: Int64, withContext mContext: MeasurementContext) -> MeasurementEntity {
        var ret: MeasurementEntity?
        let syncGroup = DispatchGroup()
        syncGroup.enter()
        createMeasurement(at: timestamp, withContext: mContext) { measurement in
            ret = MeasurementEntity(identifier: measurement.identifier, context: mContext)
            syncGroup.leave()
        }

        guard syncGroup.wait(timeout: DispatchTime.now() + .seconds(2)) == .success else {
            fatalError("PersistenceLayer.createMeasurement(at: \(timestamp), withContext: \(mContext.rawValue)): Unable to create measurement!")
        }
        return ret!
    }

    /**
     * Creates a new `measurement` asynchronuously and informs the caller when finished.
     *
     * - Parameters:
     *    - at: The time the measurement has been started at in milliseconds since the first of january 1970 (epoch).
     *    - withContext: The measurement context the new measurement is created in.
     *    - onFinishedCall: Handler that is called with the new measurement as parameter when the measurement has been stored in the database.
     */
    public func createMeasurement(at timestamp: Int64, withContext mContext: MeasurementContext, onFinishedCall handler: @escaping ((MeasurementMO) -> Void)) {
        container.performBackgroundTask { context in
            // This checks if a measurement with that identifier already exists and generates a new identifier until it finds one with no corresponding measurement. This is required to handle legacy data and installations, that still have measurements with falsely generated data.
            var identifier = self.nextIdentifier
            while self.load(measurementIdentifiedBy: identifier, from: context) != nil {
                identifier = self.nextIdentifier
            }

            if let description = NSEntityDescription.entity(forEntityName: "Measurement", in: context) {
                let measurement = MeasurementMO(entity: description, insertInto: context)
                measurement.timestamp = timestamp
                measurement.identifier = identifier
                measurement.synchronized = false
                measurement.context = mContext.rawValue
                context.saveRecursively()

                handler(measurement)
            } else {
                fatalError("PersistenceLayer.createMeasurement(at: \(timestamp), withContext: \(mContext.rawValue): Unable to create measurement!")
            }
        }
    }

    // TODO: Delete Accelerations as well.
    /**
     Deletes the measurement from the data storage on a background thread. Calls the provided handler when deletion has been completed.
     
     - Parameters:
     - measurement: The measurement to delete from the data storage.
     - onFinishedCall: The handler to call, when deletion has completed.
     */
    func delete(measurement: MeasurementEntity, onFinishedCall handler: @escaping (() -> Void)) {
        container.performBackgroundTask { context in
            let measurementIdentifier = measurement.identifier
            guard let measurement = self.load(measurementIdentifiedBy: measurement.identifier, from: context) else {
                fatalError("PersistenceLayer.delete(measurement: \(measurementIdentifier): Unable to load measurement!")
            }

            let accelerationFile = AccelerationsFile()
            do {
                try accelerationFile.remove(from: measurement)
            } catch let error {
                fatalError("PersistenceLayer.delete(measurement: \(measurement)): Unable to remove accelerations due to \(error.localizedDescription).")
            }

            context.delete(measurement)
            context.saveRecursively()
            handler()
        }
    }

    @available(*, deprecated, message: "Please use the asynchronous version `delete` instead.")
    func syncDelete(measurement: MeasurementEntity) {
        let syncGroup = DispatchGroup()
        syncGroup.enter()
        delete(measurement: measurement) {
            syncGroup.leave()
        }
        guard syncGroup.wait(timeout: DispatchTime.now() + .seconds(2)) == .success else {
            fatalError("PersistenceLayer.syncDelete(measurement: \(measurement.identifier)): Unable to delete measurements from data storage!")
        }
    }

    /**
     Deletes everything from the data storage.
     
     - Parameter onFinishedCall: A handler called after deletion is complete.
     */
    func delete(onFinishedCall handler: @escaping () -> Void) {
        container.performBackgroundTask { context in
            let syncGroup = DispatchGroup()
            syncGroup.enter()
            self.loadMeasurements(onFinishedCall: { (measurements) in
                measurements.forEach({ (measurement) in
                    // debugPrint("Deleting measurement: \(measurement.identifier).")
                    do {
                        let object = try context.existingObject(with: measurement.objectID)
                        context.delete(object)
                    } catch {
                        fatalError("PersistenceLayer.delete(): Unable to delete measurements!")
                    }
                })
                syncGroup.leave()
            })
            guard syncGroup.wait(timeout: DispatchTime.now() + .seconds(2)) == .success else {
                fatalError("PersistenceLayer.delete(): Asynchronous delete was not successful.")
            }
            context.saveRecursively()
            handler()
        }
    }

    @available(*, deprecated, message: "Please use the asynchronous version `delete` instead!")
    func syncDelete() {
        let syncGroup = DispatchGroup()
        syncGroup.enter()
        delete {
            syncGroup.leave()
        }
        guard syncGroup.wait(timeout: DispatchTime.now() + .seconds(2)) == .success else {
            fatalError("PersistenceLayer.syncDelete(): Unable to delete measurements from data storage!")
        }
    }

    /**
     Strips the provided measurement of all accelerations.
     
     - Parameters:
     - measurement: The measurement to strip of accelerations
     */
    func clean(measurement: MeasurementEntity, whenFinishedCall finishedHandler: @escaping () -> Void) {
        container.performBackgroundTask { context in
            do {
                let measurementIdentifier = measurement.identifier
                guard let measurement = self.load(measurementIdentifiedBy: measurementIdentifier, from: context) else {
                    throw PersistenceError.dataNotLoadable(measurement: measurementIdentifier)
                }

                measurement.synchronized = true
                let accelerationsFile = AccelerationsFile()
                try accelerationsFile.remove(from: measurement)

                context.saveRecursively()
                finishedHandler()
            } catch let error {
                fatalError("PersistenceLayer.clean(measurement: \(measurement.identifier)): Unable to load measurement! Error \(error).")
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
    func save(locations: [GeoLocation], toMeasurement measurement: MeasurementEntity, onFinished handler: @escaping (MeasurementMO) -> Void = {_ in }) {
        container.performBackgroundTask { context in
            let measurementIdentifier = measurement.identifier
            guard let measurement = self.load(measurementIdentifiedBy: measurementIdentifier, from: context) else {
                fatalError("PersistenceLayer.save(locations: \(locations.count), toMeasurement: \(measurementIdentifier)): Unable to load measurement!")
            }

            self.internalSave(locations: locations, toMeasurement: measurement, onContext: context)
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            context.saveRecursively()
            context.refresh(measurement, mergeChanges: true)
            handler(measurement)
        }
    }

    /**
     Saves the provided `GeoLocation` instances to the data storage. This is an internal save method that should only run on a `PersistenceContainer` background thread.

     - Parameters:
     - locations: The `GeoLocation` instances to save.
     - toMeasurement: The measurement to save to.
     - onContext: The `NSManagedObjectContext` to save the data to.
     */
    private func internalSave(locations: [GeoLocation], toMeasurement measurement: MeasurementMO, onContext context: NSManagedObjectContext) {
        locations.forEach { location in
            let dbLocation = GeoLocationMO.init(entity: GeoLocationMO.entity(), insertInto: context)
            dbLocation.lat = location.latitude
            dbLocation.lon = location.longitude
            dbLocation.speed = location.speed
            dbLocation.timestamp = location.timestamp
            dbLocation.accuracy = location.accuracy
            measurement.addToGeoLocations(dbLocation)
        }
    }

    /**
     Stores the provided `location` and `accelerations` to the provided measurement.

     - Parameters:
     - accelerations: An array of `Acceleration` instances to store.
     - toMeasurement: The measurement to store the `location` and `accelerations` to.
     - onFinished: The optional handler to call as soon as the database operation has finished.
     - Throws: If accessing the local file system failes for some reason and thus the `Acceleration` instances can not be saved.
     */
    func save(accelerations: [Acceleration], toMeasurement measurement: MeasurementEntity, onFinished handler: @escaping (() -> Void) = {}) {
        container.performBackgroundTask { context in
            do {
                let measurementIdentifier = measurement.identifier
                guard let measurement = self.load(measurementIdentifiedBy: measurementIdentifier, from: context) else {
                    throw PersistenceError.dataNotLoadable(measurement: measurementIdentifier)
                }

                try self.internalSave(accelerations: accelerations, toMeasurement: measurement)
                measurement.accelerationsCount = measurement.accelerationsCount.advanced(by: accelerations.count)

                context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                context.saveRecursively()
                context.refresh(measurement, mergeChanges: true)
                handler()
            } catch let error {
                // TODO: Do not use a fatal error but rather a status provided to the handler.
                fatalError("PersistenceLayer.save(accelerations: \(accelerations.count), toMeasurement: \(measurement.identifier)): Unable to load measurement! Error \(error).")
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
    private func load(measurementIdentifiedBy identifier: Int64, from context: NSManagedObjectContext) -> MeasurementMO? {
        let fetchRequest: NSFetchRequest<MeasurementMO> = MeasurementMO.fetchRequest()
        // The following needs to use an Objective-C number. That is why `measurementIdentifier` is wrapped in `NSNumber`
        fetchRequest.predicate = NSPredicate(format: "identifier==%@", NSNumber(value: identifier))

        do {
            let results = try context.fetch(fetchRequest)
            if results.count == 1 {
                return results[0]
            } else {
                return nil
            }
        } catch {
            fatalError("PersistenceLayer.load(measurementIdentifier: \(identifier)): Unable to fetch any results due to \(error)")
        }
    }

    /**
     Loads the data belonging to the provided `measurement` in the background an calls `onFinishedCall` with the data storage representation of that `measurement`. Using that represenation is not thread safe. Do not use it outside of the handler.
     
     - Parameters:
     - measurement: The `measurement` to load.
     - onFinishedCall: The handler to call when loading the `measurement` has finished
     */
    public func load(measurementIdentifiedBy identifier: Int64, onFinishedCall handler: @escaping (MeasurementMO) -> Void) {
        container.performBackgroundTask { context in
            if let measurement = self.load(measurementIdentifiedBy: identifier, from: context) {
                handler(measurement)
            } else {
                fatalError("Unable to load measurement with identifier \(identifier).")
            }
        }
    }

    /**
     Loads all the measurements from the data storage. Runs asynchronously in the background and calls a handler after loading has been completed. You should never use the objects in the provided array outside of the handler, since they are not thread safe and lose all data if transfered outside.
     
     - Parameters:
     - handler: The handler to call after loading the measurements has finished.
     */
    public func loadMeasurements(onFinishedCall handler: @escaping ([MeasurementMO]) -> Void) {
        container.performBackgroundTask { (context) in
            let request: NSFetchRequest<MeasurementMO> = MeasurementMO.fetchRequest()
            do {
                let fetchResult = try context.fetch(request)
                handler(fetchResult)
            } catch {
                fatalError("PersistenceLayer.loadMeasurements(): Unable to load due to: \(error.localizedDescription)")
            }
        }
    }

    /**
     Loads only those measurements that have not been synchronized to a Cyface database yet.

     - Parameter onFinishedCall: Handler called when loading the not synchronized measurements has finished. This provides the loaded measurements as an array, which will be empty if there are no such measurements.
    */
    public func loadSynchronizableMeasurements(onFinishedCall handler: @escaping ([MeasurementMO]) -> Void) {
        container.performBackgroundTask { (context) in
            let request: NSFetchRequest<MeasurementMO> = MeasurementMO.fetchRequest()
            // Fetch only not synchronized measurements
            request.predicate = NSPredicate(format: "synchronized == %@", NSNumber(value: false))
            do {
                let fetchResult = try context.fetch(request)
                handler(fetchResult)
            } catch {
                fatalError("PersistenceLayer.loadSynchronizableMeasurements(): Unable to load due to \(error.localizedDescription)")
            }
        }
    }

    /**
     Counts the amount of measurements currently stored in the data store, asynchronously in the background.
     
     - Parameter handler: The handler called after counting has finished. This handler receives the result as a parameter.
     */
    public func countMeasurements(onFinishedCall handler: @escaping (Int) -> Void) {
        container.performBackgroundTask { (context) in
            let request: NSFetchRequest<MeasurementMO> = MeasurementMO.fetchRequest()
            let count = try? context.count(for: request)
            handler(count ?? 0)
        }
    }

    /**
     Counts all the measurements currently saved in the database.

     - Returns: The number of measurements in the database.
     */
    public func syncCountMeasurements() -> Int {
        let syncGroup = DispatchGroup()
        var ret: Int?
        syncGroup.enter()
        countMeasurements { count in
            ret = count
            syncGroup.leave()
        }
        guard syncGroup.wait(timeout: DispatchTime.now() + .seconds(2)) == .success else {
            fatalError("PersistenceLayer.syncDelete(): Unable to delete measurements from data storage!")
        }
        return ret!
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

enum PersistenceError: Error {
    case dataNotLoadable(measurement: Int64)
}
