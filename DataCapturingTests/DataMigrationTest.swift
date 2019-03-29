//
//  DataMigrationTest.swift
//  DataCapturingTests
//
//  Created by Team Cyface on 18.03.19.
//  Copyright © 2019 Cyface GmbH. All rights reserved.
//

import XCTest
import CoreData
@testable import DataCapturing

class DataMigrationTest: XCTestCase {

    override func setUp() {
        FileManager.clearTempDirectoryContents()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLoadMappingModel() throws {
        let oldResource = "3"
        let newResource = "4"
        let subdirectory = "CyfaceModel.momd"
        let bundle = Bundle(identifier: "de.cyface.DataCapturing")
        let oldMomURL = bundle?.url(forResource: oldResource, withExtension: "mom", subdirectory: subdirectory)
        let newMomURL = bundle?.url(forResource: newResource, withExtension: "mom", subdirectory: subdirectory)
        XCTAssertNotNil(oldMomURL)
        XCTAssertNotNil(newMomURL)

        let mappingModel = NSMappingModel(from: [bundle!], forSourceModel: NSManagedObjectModel(contentsOf: oldMomURL!), destinationModel: NSManagedObjectModel(contentsOf: newMomURL!))

        XCTAssertNotNil(mappingModel)
    }

    func testMigrationV1ToV2() throws {
        // Arrange, Act
        let context = migrate(fromVersion: .version1, toVersion: .version2, usingTestData: "V1TestData.sqlite")

        // Assert
        try assertV2(onContext: context)
    }

    func testMigrationV2ToV3() throws {
        // Arrange, Act
        let context = migrate(fromVersion: .version2, toVersion: .version3, usingTestData: "V2TestData.sqlite")

        // Assert
        try assertV3(onContext: context)
    }

    func testMigrationV3ToV4() throws {
        // Arrange, Act
        let context = migrate(fromVersion: .version3, toVersion: .version4, usingTestData: "V3TestData.sqlite")

        // Assert
        try assertV4(onContext: context, withFirstLocationCount: 300, withSecondLocationCount: 200)
    }

    func testMigrationV1ToV4() throws {
        // Arrange, Act
        let context = migrate(fromVersion: .version1, toVersion: .version4, usingTestData: "V1TestData.sqlite")

        // Assert
        try assertV4(onContext: context, withFirstLocationCount: 200, withSecondLocationCount: 100)
    }

    func migrate(fromVersion: CoreDataMigrationVersion, toVersion: CoreDataMigrationVersion, usingTestData testDatastore: String) -> NSManagedObjectContext {
        // Arrange
        guard let bundle = Bundle(identifier: "de.cyface.DataCapturing") else {
            fatalError()
        }
        let migrator = CoreDataMigrator()
        let datastore = FileManager.moveFileFromBundleToTempDirectory(filename: testDatastore)
        addTeardownBlock {
            FileManager.clearTempDirectoryContents()
        }
        XCTAssertTrue(migrator.requiresMigration(at: datastore, toVersion: toVersion, inBundle: bundle))

        // Act
        migrator.migrateStore(at: datastore, toVersion: toVersion, inBundle: bundle)

        // Assert
        XCTAssertTrue(try datastore.checkPromisedItemIsReachable())

        let model = NSManagedObjectModel.managedObjectModel(forResource: toVersion.rawValue, inBundle: bundle)
        let context = NSManagedObjectContext(model: model, storeURL: datastore)
        addTeardownBlock {
            context.destroyStore()
        }
        return context
    }

    /*func loadContainer(from model: String, with version: String, from bundleIdentifiedBy: String) -> NSPersistentContainer {
     let modelURL = Bundle(identifier: bundleIdentifiedBy)?.url(forResource: model, withExtension: "momd")
     let managedObjectModelBundle = Bundle(url: modelURL!)
     let managedObjectModelVersionURL = managedObjectModelBundle!.url(forResource: version, withExtension: "mom")

     let managedObjectModel = NSManagedObjectModel.init(contentsOf: managedObjectModelVersionURL!)!

     let container = NSPersistentContainer(name: model, managedObjectModel: managedObjectModel)

     let description = NSPersistentStoreDescription()
     description.type = storeType
     description.shouldInferMappingModelAutomatically = false
     description.shouldMigrateStoreAutomatically = false
     container.persistentStoreDescriptions = [description]

     container.loadPersistentStores { (_, _) in
     // Nothing to do here
     }
     return container
     }

     func loadContainer(from model: String, with version: String, from bundleIdentifiedBy: String, at location: URL) -> NSPersistentContainer {
     let modelURL = Bundle(identifier: bundleIdentifiedBy)?.url(forResource: model, withExtension: "momd")
     let managedObjectModelBundle = Bundle(url: modelURL!)
     let managedObjectModelVersionURL = managedObjectModelBundle!.url(forResource: version, withExtension: "mom")

     let managedObjectModel = NSManagedObjectModel.init(contentsOf: managedObjectModelVersionURL!)!

     let container = NSPersistentContainer(name: model, managedObjectModel: managedObjectModel)

     let description = NSPersistentStoreDescription()
     description.type = NSSQLiteStoreType
     description.url = location
     description.shouldInferMappingModelAutomatically = false
     description.shouldMigrateStoreAutomatically = false
     container.persistentStoreDescriptions = [description]

     container.loadPersistentStores { (_, _) in
     // Nothing to do here
     }
     return container
     }*/

    func cleanDatabaseFiles(oldDatabase: URL, newDatabase: URL) {
        do {
            let fileManager = FileManager.default
            let oldDatabaseSHM = oldDatabase.deletingPathExtension().appendingPathExtension("sqlite-shm")
            let oldDatabaseWAL = oldDatabase.deletingPathExtension().appendingPathExtension("sqlite-wal")
            let newDatabaseSHM = newDatabase.deletingPathExtension().appendingPathExtension("sqlite-shm")
            let newDatabaseWAL = newDatabase.deletingPathExtension().appendingPathExtension("sqlite-wal")
            if try oldDatabase.checkPromisedItemIsReachable() {
                try fileManager.removeItem(at: oldDatabase)
            }
            if try oldDatabaseSHM.checkPromisedItemIsReachable() {
                try fileManager.removeItem(at: oldDatabaseSHM)
            }
            if try oldDatabaseWAL.checkPromisedItemIsReachable() {
                try fileManager.removeItem(at: oldDatabaseWAL)
            }
            if try newDatabase.checkPromisedItemIsReachable() {
                try fileManager.removeItem(at: newDatabase)
            }
            if try newDatabaseSHM.checkPromisedItemIsReachable() {
                try fileManager.removeItem(at: newDatabaseSHM)
            }
            if try newDatabaseWAL.checkPromisedItemIsReachable() {
                try fileManager.removeItem(at: newDatabaseWAL)
            }
        } catch let error {
            fatalError("\(error)")
        }
    }

    func assertV2(onContext context: NSManagedObjectContext) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Measurement")

        let migratedMeasurements = try context.fetch(request)

        XCTAssertEqual(migratedMeasurements.count, 2)
        XCTAssertNotNil(migratedMeasurements.first?.value(forKeyPath: "context"))
        XCTAssertEqual(migratedMeasurements.first?.value(forKeyPath: "context") as? String, "BICYCLE")
    }

    func assertV3(onContext context: NSManagedObjectContext) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Measurement")

        let migratedMeasurements = try context.fetch(request)

        XCTAssertEqual(migratedMeasurements.count, 2)
        XCTAssertEqual(migratedMeasurements.first?.primitiveValue(forKey: "accelerationCount") as? Int, 0)
    }

    func assertV4(onContext context: NSManagedObjectContext, withFirstLocationCount firstLocationCount: Int, withSecondLocationCount secondLocationCount: Int) throws {
        let measurementFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Measurement")
        let sort = NSSortDescriptor(key: "identifier", ascending: false)
        measurementFetchRequest.sortDescriptors = [sort]
        let trackFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Track")
        let migratedMeasurements = try context.fetch(measurementFetchRequest)

        XCTAssertEqual(migratedMeasurements.count, 2)
        guard let tracksFromFirstMeasurement = migratedMeasurements[0].value(forKey: "tracks") as? NSOrderedSet else {
            XCTFail("Unable to load tracks from the first migrated measurement!")
            return
        }
        guard let tracksFromSecondMeasurement = migratedMeasurements[1].value(forKey: "tracks") as? NSOrderedSet else {
            XCTFail("Unable to load tracks from the second migrated measurement!")
            return
        }
        XCTAssertEqual(tracksFromFirstMeasurement.count, 1)
        XCTAssertEqual(tracksFromSecondMeasurement.count, 1)

        let tracks = try context.fetch(trackFetchRequest)
        XCTAssertEqual(tracks.count, 2)

        guard let trackOne = tracksFromFirstMeasurement.firstObject as? NSManagedObject else {
            XCTFail("Unable to load track from first migrated measurement!")
            return
        }
        guard let trackTwo = tracksFromSecondMeasurement.firstObject as? NSManagedObject else {
            XCTFail("Unable to load track from second migrated measurement!")
            return
        }
        guard let locationsFromTrackOne = trackOne.value(forKey: "locations") as? NSOrderedSet else {
            XCTFail("Unable to load geo locations from first track!")
            return
        }
        guard let locationsFromTrackTwo = trackTwo.value(forKey: "locations") as? NSOrderedSet else {
            XCTFail("Unable to load geo locations from second track!")
            return
        }
        XCTAssertEqual(locationsFromTrackOne.count, firstLocationCount)
        XCTAssertEqual(locationsFromTrackTwo.count, secondLocationCount)
    }

    /*func skip_testExample() throws {
        guard let bundle = Bundle(identifier: "de.cyface.DataCapturing") else {
            fatalError()
        }

        let migrator = CoreDataMigrator()
        let location = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let database = location.appendingPathComponent("V3TestData").appendingPathExtension("sqlite")
        let container = loadContainer(from: "CyfaceModel", with: "3", from: "de.cyface.DataCapturing", at: database)
        try DataSetCreator.createV3Data(in: container)

        for store in container.persistentStoreCoordinator.persistentStores {
            try container.persistentStoreCoordinator.remove(store)
        }
        migrator.forceWALCheckpointingForStore(at: database, inBundle: bundle)
        print("done")
    }*/
}

extension FileManager {

    // MARK: - Temp

    static func clearTempDirectoryContents() {
        let tmpDirectoryContents = try! FileManager.default.contentsOfDirectory(atPath: NSTemporaryDirectory())
        tmpDirectoryContents.forEach {
            let fileURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent($0)
            try? FileManager.default.removeItem(atPath: fileURL.path)
        }
    }

    static func moveFileFromBundleToTempDirectory(filename: String) -> URL {
        let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: destinationURL)
        let bundleURL = Bundle(for: DataMigrationTest.self).resourceURL!.appendingPathComponent(filename)
        try? FileManager.default.copyItem(at: bundleURL, to: destinationURL)

        return destinationURL
    }
}

extension NSManagedObjectContext {

    // MARK: Model

    convenience init(model: NSManagedObjectModel, storeURL: URL) {
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try! persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)

        self.init(concurrencyType: .mainQueueConcurrencyType)

        self.persistentStoreCoordinator = persistentStoreCoordinator
    }

    // MARK: - Destroy

    func destroyStore() {
        persistentStoreCoordinator?.persistentStores.forEach {
            try? persistentStoreCoordinator?.remove($0)
            try? persistentStoreCoordinator?.destroyPersistentStore(at: $0.url!, ofType: $0.type, options: nil)
        }
    }
}
