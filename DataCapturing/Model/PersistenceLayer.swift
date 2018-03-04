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
 */
public class PersistenceLayer {

    let context: NSManagedObjectContext

    let container: NSPersistentContainer

    var lastIdentifier: Int64?

    var nextIdentifier: Int64 {
        if let lastIdentifier = lastIdentifier {
            self.lastIdentifier = lastIdentifier + 1
            return lastIdentifier + 1
        } else {
            lastIdentifier = Int64(countMeasurements())
            return lastIdentifier!
        }
    }

    public init() {
        // The following code is necessary to load the CyfaceModel from the DataCapturing framework. It is only necessary because we are using a framework. Usually this would be much simpler as shown by many tutorials.
        // Details are available from the following StackOverflow Thread: https://stackoverflow.com/questions/42553749/core-data-failed-to-load-model
        let momdName = "CyfaceModel"

        guard let modelURL = Bundle(for: type(of: self)).url(forResource: momdName, withExtension:"momd") else {
            fatalError("Error loading model from bundle")
        }

        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }

        container = NSPersistentContainer(name: momdName, managedObjectModel: mom)

        container.loadPersistentStores() { description, error in
            if let error = error {
                fatalError("Unable to load persistent storage \(error)")
            }
        }

        context = container.viewContext
    }

    func createMeasurement(at timestamp: Int64) -> MeasurementMO {
        let identifier = nextIdentifier
        if let description = NSEntityDescription.entity(forEntityName: "Measurement", in: context) {
            let measurement = MeasurementMO(entity: description, insertInto: context)
            measurement.timestamp = timestamp
            measurement.identifier = identifier
            return measurement
        } else {
            fatalError("Unable to create measurement.")
        }
    }

    func createAcceleration(x ax: Double, y ay: Double, z az: Double, at timestamp: Int64) -> AccelerationPointMO {
        let acceleration = NSEntityDescription.insertNewObject(forEntityName: "Acceleration", into: context) as! AccelerationPointMO
        acceleration.ax = ax
        acceleration.ay = ay
        acceleration.az = az
        acceleration.timestamp = timestamp

        return acceleration
    }

    func createGeoLocation(latitude lat: Double, longitude lon: Double, accuracy acc: Double, speed spd: Double, at timestamp: Int64) -> GeoLocationMO {
        let location = NSEntityDescription.insertNewObject(forEntityName: "GeoLocation", into: context) as! GeoLocationMO

        location.accuracy = acc
        location.lat = lat
        location.lon = lon
        location.speed = spd
        location.timestamp = timestamp

        return location
    }

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

    public func countMeasurements() -> Int {
        let request: NSFetchRequest<MeasurementMO> = MeasurementMO.fetchRequest()
        do {
            let count = try context.count(for: request)
            return count
        } catch {
            fatalError("Unable to load measurements from data store: \(error).")
        }
    }

    // TODO: this has the potential to load much data into memory. Maybe refactor this if problems occur.
    public func loadMeasurement(withIdentifier identifier: Int64) -> MeasurementMO? {

        for measurement in loadMeasurements() {
            if measurement.identifier==identifier {
                return measurement
            }
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

    /// Deletes measurements from the persistent data store. Do not forget to call `save()` to commit the changes.
    func deleteMeasurements() {
        loadMeasurements().forEach() { m in
            context.delete(m)
        }
    }

    /// Deletes one specific measurement from the persistent data store. Do not forget to call `save()`to commit the changes.
    func delete(measurement value: MeasurementMO) {
        context.delete(value)
    }

    func save() {
        do {
            try context.save()
        } catch {
            fatalError("Unable to save to persistence context: \(error)")
        }
    }
}
