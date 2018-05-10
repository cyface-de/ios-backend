//
//  PersistenceLayer.swift
//  DataCapturing
//
//  Created by Team Cyface on 04.12.17.
//  Copyright © 2017 Cyface GmbH. All rights reserved.
//

import Foundation
import CoreData

/**
 Read access is public while manipulation of the data stored is restricted to the framework.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 1.0.0
 */
public class PersistenceLayer {

    // MARK: - Properties
    /// The context to use for accessing CoreData.
    private lazy var context: NSManagedObjectContext = {
        return container.viewContext
    }()

    /// Container for the persistent object model.
    private lazy var container: NSPersistentContainer = {
        /*
         The following code is necessary to load the CyfaceModel from the DataCapturing framework.
         It is only necessary because we are using a framework.
         Usually this would be much simpler as shown by many tutorials.
         Details are available from the following StackOverflow Thread:
         https://stackoverflow.com/questions/42553749/core-data-failed-to-load-model
         */
        let momdName = "CyfaceModel"

        guard let modelURL = Bundle(for: type(of: self)).url(forResource: momdName, withExtension: "momd") else {
            fatalError("Error loading model from bundle")
        }

        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }

        let container = NSPersistentContainer(name: momdName, managedObjectModel: mom)

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unable to load persistent storage \(error)")
            }
        }

        return container
    }()

    /// The identifier that has been assigned the last to a new `Measurement`.
    var lastIdentifier: Int64?

    /// The next identifier to assign to a new `Measurement`.
    var nextIdentifier: Int64 {
        get {
            let persistentStore = container.persistentStoreCoordinator.persistentStores[0]
            let coordinator = container.persistentStoreCoordinator

            if lastIdentifier == nil {
                // identifier is already stored as metadata.
                if let currentIdentifier = coordinator.metadata(for: persistentStore)["de.cyface.mid"] as! Int64? {
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
            coordinator.setMetadata(["de.cyface.mid":nextIdentifier], for: persistentStore)
            return nextIdentifier
        }
    }

    private lazy var backgroundContext: NSManagedObjectContext = {
        return container.newBackgroundContext()
    }()

    private lazy var mainThreadContext: NSManagedObjectContext = {
        var mainQueueContext =
            NSManagedObjectContext(concurrencyType:
                .mainQueueConcurrencyType)
        mainQueueContext.parent = backgroundContext
        mainQueueContext.mergePolicy =
        NSMergeByPropertyObjectTrumpMergePolicy
        return mainQueueContext
    }()

    // MARK: - Initializers

    /// Public constructor usable by external callers.
    public init() {}

    // MARK: - Database Writing Methods

    /**
     Creates a new measurement with the provided `timestamp`.

     - Parameter timestamp: The time the measurement has been started at in milliseconds since the first of january 1970 (epoch).
     */
    @available(*, deprecated)
    func createMeasurement(at timestamp: Int64) -> Int64 {
        let identifier = nextIdentifier
        if let description = NSEntityDescription.entity(forEntityName: "Measurement", in: context) {
            let measurement = MeasurementMO(entity: description, insertInto: context)
            measurement.timestamp = timestamp
            measurement.identifier = identifier
            measurement.synchronized = false
            
            save()
            return identifier
        } else {
            fatalError("Unable to create measurement!")
        }
    }

    public func createMeasurement2(at timestamp: Int64) -> Int64 {
        let identifier = nextIdentifier
        var ret: Int64?
        let syncGroup = DispatchGroup()
        syncGroup.enter()
        container.performBackgroundTask { (context) in
            if let description = NSEntityDescription.entity(forEntityName: "Measurement", in: context) {
                let measurement = MeasurementMO(entity: description, insertInto: context)
                measurement.timestamp = timestamp
                measurement.identifier = identifier
                ret = measurement.identifier
            } else {
                fatalError("Unable to create measurement!")
            }

            context.saveRecursively()
            syncGroup.leave()
        }

        syncGroup.wait(timeout: DispatchTime.now() + .seconds(2))
        return ret!
    }

    /**
     Creates a new acceleration in the current data store.

     - Parameters:
     - x: The acceleration in device x direction
     - y: The acceleration in device y direction
     - z: The acceleration in device z direction
     - at: Timestamp in milliseconds since the first of january 1970 (epoch).
     - Returns: A new acceleration object, that mirrors the current state of that acceleration in the database.
     */
    @available(*, deprecated)
    func createAcceleration(x ax: Double, y ay: Double, z az: Double, at timestamp: Int64) -> AccelerationPointMO {
        guard let acceleration = NSEntityDescription.insertNewObject(forEntityName: "Acceleration", into: context) as? AccelerationPointMO else {
            fatalError("Unable to create new acceleration in CoreData!")
        }
        acceleration.ax = ax
        acceleration.ay = ay
        acceleration.az = az
        acceleration.timestamp = timestamp

        return acceleration
    }

    /**
     Creates a new geo location in the current database.

     - Parameters:
     - latitude: The geographic latitude of the newly created geo location.
     - longitude: The geographic longitude of the newly created geo location.
     - accuracy: The accuracy of the captured geo location in meters.
     - speed: The speed of the capturing device at the moment of capturing the geo location.
     - at: The timestamp at which the geo location has been captured in milliseconds since the first of january 1970.
     - Returns: The newly created geo location as it is stored in the data store.
     */
    @available(*, deprecated)
    func createGeoLocation(latitude lat: Double, longitude lon: Double, accuracy acc: Double, speed spd: Double, at timestamp: Int64) -> GeoLocationMO {
        guard let location = NSEntityDescription.insertNewObject(forEntityName: "GeoLocation", into: context) as? GeoLocationMO else {
            fatalError("Unable to create new location in CoreData!")
        }

        location.accuracy = acc
        location.lat = lat
        location.lon = lon
        location.speed = spd
        location.timestamp = timestamp

        return location
    }

    /// Deletes measurements from the persistent data store.
    @available(*, deprecated)
    func deleteMeasurements() {
        loadMeasurements().forEach { measurement in
            context.delete(measurement)
        }
        save()
    }

    /**
     Deletes one specific measurement from the persistent data store.

     - Parameter measurement: The `MeasurementMO` to delete from the database.
     */
    @available(*, deprecated)
    func delete(measurement value: MeasurementMO) {
        if let accelerations = value.accelerations {
            for acceleration in accelerations {
                value.removeFromAccelerations(acceleration)
                context.delete(acceleration)
            }
        }
        if let locations = value.geoLocations {
            for location in locations {
                value.removeFromGeoLocations(location)
                context.delete(location)
            }
        }
        context.delete(value)

        save()
    }

    func privatelyDelete(measurement identifier: Int64, onFinishedCall handler: @escaping (() -> Void)) {
        container.performBackgroundTask { [unowned self] context in
            let measurement = self.load(identifier, from: context)
            context.delete(measurement)
            context.saveRecursively()
            handler()
        }
    }

    /**
     Removes all accelerations, rotations and directions from a measurement. This can be used to save space after successful data synchronization, if you would like to keep the geo location tracks.

     - Parameter measurement: The `MeasurementMO` to clean of all sensor data.
     */
    @available(*, deprecated)
    func clean(measurement: MeasurementMO) {
        if let accelerations = measurement.accelerations {
            for acceleration in accelerations {
                measurement.removeFromAccelerations(acceleration)
                context.delete(acceleration)
            }
        }
        save()
    }

    func privatelyClean(measurementIdentifiedBy identifier: Int64, whenFinishedCall finishedHandler: @escaping () -> Void) {
        container.performBackgroundTask { [unowned self] (context) in
            let measurement = self.load(identifier, from: context)
            measurement.synchronized = true
            if let accelerations = measurement.accelerations {
                for acceleration in accelerations {
                    measurement.removeFromAccelerations(acceleration)
                    context.delete(acceleration)
                }
            }

            context.saveRecursively()
            finishedHandler()
        }
    }

    func privatelySave(toMeasurementIdentifiedBy identifier: Int64, location: GeoLocation, accelerations: [Acceleration], onFinished handler: @escaping () -> Void) {
        container.performBackgroundTask { [unowned self] (context) in
            let measurement = self.load(identifier, from: context)
            let dbLocation = GeoLocationMO.init(entity: GeoLocationMO.entity(), insertInto: context)
            dbLocation.lat = location.latitude
            dbLocation.lon = location.longitude
            dbLocation.speed = location.speed
            dbLocation.timestamp = location.timestamp
            dbLocation.accuracy = location.accuracy
            measurement.addToGeoLocations(dbLocation)

            accelerations.forEach { acceleration in
                let dbAcceleration = AccelerationPointMO.init(entity: AccelerationPointMO.entity(), insertInto: context)
                dbAcceleration.ax = acceleration.x
                dbAcceleration.ay = acceleration.y
                dbAcceleration.az = acceleration.z
                dbAcceleration.timestamp = acceleration.timestamp
                measurement.addToAccelerations(dbAcceleration)
            }

            context.saveRecursively()
            handler()
        }
    }

    // MARK: - Database Read Only Methods

    private func load(_ measurementIdentifier: Int64, from context: NSManagedObjectContext) -> MeasurementMO {
        let fetchRequest: NSFetchRequest<MeasurementMO> = MeasurementMO.fetchRequest()
        // The following needs to use an Objective-C number. That is why `measurementIdentifier` is wrapped in `NSNumber`
        fetchRequest.predicate = NSPredicate(format: "identifier==%@", NSNumber(value: measurementIdentifier))

        if let results = try? context.fetch(fetchRequest) {
            if results.count == 1 {
                return results[0]
            } else {
                fatalError("PersistenceLayer.load(measurementIdentifier: \(measurementIdentifier)): Wrong count of results: \(results.count).")
            }
        } else {
            fatalError("PersistenceLayer.load(measurementIdentifier: \(measurementIdentifier)): Unable to fetch any results.")
        }
    }

    public func privatelyLoad(measurementIdentifiedBy identifier: Int64, andCallWhenFinished handler: @escaping (MeasurementMO) -> Void) {
        container.performBackgroundTask { [unowned self] (context) in
            let measurement = self.load(identifier, from: context)
            handler(measurement)
        }
    }

    public func privatelyLoadMeasurements(onFinished handler: @escaping ([MeasurementMO]) -> Void) {
        container.performBackgroundTask { (context) in
            let request: NSFetchRequest<MeasurementMO> = MeasurementMO.fetchRequest()
            do {
                let fetchResult = try context.fetch(request)
                handler(fetchResult)
            } catch {
                fatalError("PersistenceLayer.privatelyLoadMeasurements(): Unable to load due to: \(error.localizedDescription)")
            }
        }
    }

    /**
     Loads all measurements from the data store.

     - Returns: The currently stored measurements from the data store.
     */
    @available(*, deprecated)
    public func loadMeasurements() -> [MeasurementMO] {
        let request: NSFetchRequest<MeasurementMO> = MeasurementMO.fetchRequest()
        do {
            let fetchedMeasurements = try context.fetch(request)
            for measurement in fetchedMeasurements {
                debugPrint("PersistenceLayer.loadMeasurements(): Loaded measurement with identifier \(measurement.identifier).")
            }
            return fetchedMeasurements
        } catch {
            fatalError("Unable to load measurements from data store: \(error).")
        }
    }

    /**
     Counts the amount of measurements currently stored in the data store.

     - Returns: The count of measurements in the data store.
     */
    @available(*, deprecated)
    public func countMeasurements() -> Int {
        let request: NSFetchRequest<MeasurementMO> = MeasurementMO.fetchRequest()
        do {
            let count = try context.count(for: request)
            return count
        } catch {
            fatalError("Unable to load measurements from data store: \(error).")
        }
    }

    public func privatelyCountMeasurements(onFinished handler: @escaping (Int) -> Void) {
        container.performBackgroundTask { (context) in
            let request: NSFetchRequest<MeasurementMO> = MeasurementMO.fetchRequest()
            let count = try? context.count(for: request)
            handler(count ?? 0)
        }
    }

    /**
     Loads a specific measurement from the data store.

     - Parameter identifier: The database wide unique identifier of the measurement to load.
     */
    @available(*, deprecated)
    public func loadMeasurement(withIdentifier identifier: Int64) -> MeasurementMO? {

        for measurement in loadMeasurements() where measurement.identifier==identifier {
            return measurement
        }
        return nil
        /*
         let request: NSFetchRequest<MeasurementMO> = MeasurementMO.fetchRequest()

         debugPrint("PersistenceLayer.loadMeasurement(withIdentifier: \(identifier)): Preparing to load measurement with identifier \(identifier)")
         request.predicate = NSPredicate(format: "%K = %@", "identifier", String(identifier))
         do {
         debugPrint("PersistenceLayer.loadMeasurement(withIdentifier: \(identifier)): Loading measurement with identifier \(identifier).")
         let fetchResult = try context.fetch(request)
         debugPrint("PersistenceLayer.loadMeasurement(withIdentifier: \(identifier)): Got \(fetchResult.count) items")
         if fetchResult.count >= 1 {
         fatalError("PersistenceLayer.loadMeasurement(withIdentifier: \(identifier)): Identifier occured multiple times")
         } else {
         let result = fetchResult.first
         return result
         }
         } catch {
         fatalError("PersistenceLayer.loadMeasurement(withIdentifier: \(identifier)): Unable to load measurements from data store: \(error)")
         }
         return nil*/
    }

    // MARK: - Support Methods

    /// Commits all stacked changes (updates, deletes, inserts).
    @available(*, deprecated)
    func save() {
        do {
            if context.hasChanges {
                try context.save()
            }
        } catch {
            fatalError("Unable to save to persistence context: \(error)!")
        }
    }

    func save(_ privateContext: NSManagedObjectContext) {
        do {
            if privateContext.hasChanges {
                try privateContext.save()
            }
        } catch {
            fatalError("Unable to save private persistence context: \(error)!")
        }
        save()
    }

    func newPrivateQueueContext() -> NSManagedObjectContext {
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        privateContext.parent = mainThreadContext
        return privateContext
    }
}

extension NSManagedObjectContext {
    func saveRecursively() {
        performAndWait {
            if self.hasChanges {
                self.saveThisAndParentContexts()
            }
        }
    }

    func saveThisAndParentContexts() {
        do {
            try save()
            parent?.saveRecursively()
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
}
