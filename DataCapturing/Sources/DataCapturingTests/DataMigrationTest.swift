/*
 * Copyright 2019-2024 Cyface GmbH
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

import XCTest
import CoreData
import OSLog
@testable import DataCapturing

/**
 Tests that data migration between different versions of the Cyface data model are going to work as expected.

 - Author: Klemens Muthmann
 - Version: 1.3.0
 - Since: 4.0.0
 */
class DataMigrationTest: XCTestCase {

    /// Initializes the test environment by cleaning the temporary directory from any files that might have remained from failed previous tests.
    override func setUp() {
        FileManager.clearTempDirectoryContents()
    }

    /// Shuts down the test environment by cleaning the temporary directory.
    override func tearDown() {
        FileManager.clearTempDirectoryContents()
    }

    /**
     Tests that loadin a custom mapping model works. This test is used as a show case for how to load a mapping model. The code is not actually used in the app.
     */
    func testLoadMappingModel() throws {
        let oldResource = "3"
        let newResource = "4"

        // The DataCapturing bundle is part of the test bundle and needs to be loaded from within its parent bundle directly.
        let dataCapturingBundle = XCTestCase.appBundle()!

        let oldMomURL = dataCapturingBundle.url(forResource: oldResource, withExtension: "mom", subdirectory: "CyfaceModel.momd")
        let newMomURL = dataCapturingBundle.url(forResource: newResource, withExtension: "mom", subdirectory: "CyfaceModel.momd")
        XCTAssertNotNil(oldMomURL)
        XCTAssertNotNil(newMomURL)

        let mappingModel = NSMappingModel(from: [dataCapturingBundle], forSourceModel: NSManagedObjectModel(contentsOf: oldMomURL!), destinationModel: NSManagedObjectModel(contentsOf: newMomURL!))

        XCTAssertNotNil(mappingModel)
    }

    /**
     Tests a successful migration from version 1 to version 2.

     - Throws:
        - Some unspecified CoreData errors.
     */
    func testMigrationV1ToV2() throws {
        // Arrange, Act
        let context = try migrate(fromVersion: .version1, toVersion: .version2, usingTestData: "V1TestData")

        // Assert
        try assertV2(onContext: context)
    }

    /**
     Tests a successful migration from version 2 to version 3.

     - Throws:
        - Some unspecified CoreData errors.
     */
    func testMigrationV2ToV3() throws {
        // Arrange, Act
        let context = try migrate(fromVersion: .version2, toVersion: .version3, usingTestData: "V2TestData")

        // Assert
        try assertV3(onContext: context)
    }

    /**
     Tests a successful migration from version 3 to version 4.

     - Throws:
        - Some unspecified CoreData errors.
     */
    func testMigrationV3ToV4() throws {
        // Arrange, Act
        let context = try migrate(fromVersion: .version3, toVersion: .version4, usingTestData: "V3TestData")

        // Assert
        try assertV4(onContext: context, withFirstLocationCount: 300, withSecondLocationCount: 200)
    }

    /**
     Tests a successful migration from version 4 to version 5.

     - Throws:
        - Some unspecified CoreData errors.
     */
    func testMigrationV4ToV5() throws {
        // Arrange, Act
        let context = try migrate(fromVersion: .version4, toVersion: .version5, usingTestData: "V4TestData")

        // Assert
        try assertV5(onContext: context)
    }

    /**
     Tests a successful migration from version 5 to version 6.

     - Throws:
        - Some unspecified CoreData errors.
     */
    func testMigrationV5ToV6() throws {
        // Arrange, Act
        let context = try migrate(fromVersion: .version5, toVersion: .version6, usingTestData: "V5TestData")

        // Assert
        try assertV6(onContext: context)
    }

    /**
     Tests a successful migration from version 6 to version 7.

     - Throws:
        - Some unspecified CoreData errors.
     */
    func testMigrationV6ToV7() throws {
        // Arrange, Act
        let context = try migrate(fromVersion: .version6, toVersion: .version7, usingTestData: "V6TestData")

        // Assert
        try assertV7(onContext: context)
    }

    /**
     Tests a successful migration from version 1 to version 4. This tests the whole update path in one go.

     - Throws:
        - Some unspecified CoreData errors.
     */
    func testMigrationV1ToV4() throws {
        // Arrange, Act
        let context = try migrate(fromVersion: .version1, toVersion: .version4, usingTestData: "V1TestData")

        // Assert
        try assertV4(onContext: context, withFirstLocationCount: 100, withSecondLocationCount: 200)
    }

    /**
     Tests a successful migration from version 1 to version 5. This tests the whole update path in one go.

     - Throws:
        - Some unspecified CoreData errors.
     */
    func testMigrationV1ToV5() throws {
        // Arrange, Act
        let context = try migrate(fromVersion: .version1, toVersion: .version5, usingTestData: "V1TestData")

        // Assert
        try assertV5(onContext: context)
    }

    func testMigrationV9ToV10() throws {
        // Arrange, Act
        let context = try migrate(fromVersion: .version9, toVersion: .version10, usingTestData: "V9TestData")

        // Assert
        try assertV10(onContext: context)
    }

    func testMigrationV10ToV11() throws {
        // Arrange, Act
        let context = try migrate(fromVersion: .version10, toVersion: .version11, usingTestData: "V10TestData")

        // Assert
        try assertV11(onContext: context)
    }

    func testMigrationV11ToV12() throws {
        // Arrange, Act
        let context = try migrate(fromVersion: .version11, toVersion: .version12, usingTestData: "V11TestData")

        // Assert
        try assertV12(onContext: context)
    }

    /**
     Migrates a test data store `fromVersion` to a not necessarily consecutive `toVersion` using a pregenerated data store as test data.

     - Parameters:
        - fromVersion: The version of the provided pregenerated data store used as input
        - toVersion: The version to migrate the pregenerated data store to
        - usingTestData: The test data store to migrate to
     - Returns: The `NSManagedObjectContext` on the migrated data store.
     */
    func migrate(fromVersion: CoreDataMigrationVersion, toVersion: CoreDataMigrationVersion, usingTestData testDatastore: String) throws -> NSManagedObjectContext {
        // Arrange
        let migrator = CoreDataMigrator(to: toVersion)
        let bundle = XCTestCase.appBundle()!
        let datastore = FileManager.move(file: testDatastore, fromBundle: XCTestCase.testBundle()!)
        addTeardownBlock {
            FileManager.clearTempDirectoryContents()
        }
        XCTAssertTrue(try migrator.requiresMigration(at: datastore, inBundle: bundle))

        // Act
        try migrator.migrateStore(at: datastore, inBundle: bundle)

        // Assert
        XCTAssertTrue(try datastore.checkPromisedItemIsReachable())

        let model = try NSManagedObjectModel.managedObjectModel(forResource: toVersion.rawValue, inBundle: bundle, withModelName: "CyfaceModel")
        let context = NSManagedObjectContext(model: model, storeURL: datastore)
        addTeardownBlock {
            context.destroyStore()
        }
        return context
    }

    /**
     Assert a successful migration to a version 2 database.

     - Parameters:
        - onContext: A context on the version 2 data store
     - Throws:
        - Some unspecified *CoreData* errors.
     */
    func assertV2(onContext context: NSManagedObjectContext) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Measurement")

        let migratedMeasurements = try context.fetch(request)

        XCTAssertEqual(migratedMeasurements.count, 2)
        XCTAssertNotNil(migratedMeasurements.first?.value(forKeyPath: "context"))
        XCTAssertEqual(migratedMeasurements.first?.value(forKeyPath: "context") as? String, "BICYCLE")
    }

    /**
     Assert a successful migration to a version 3 database.

     - Parameters:
        - onContext: A context on the version 3 data store
     - Throws:
        - Some unspecified *CoreData* errors.
     */
    func assertV3(onContext context: NSManagedObjectContext) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Measurement")

        let migratedMeasurements = try context.fetch(request)

        XCTAssertEqual(migratedMeasurements.count, 2)
        XCTAssertEqual(migratedMeasurements.first?.primitiveValue(forKey: "accelerationCount") as? Int, 0)
    }

    /**
     Assert a successful migration to a version 4 database.

     - Parameters:
        - onContext: A context on the version 4 data store
        - withFirstLocationCount: Number of geo locations on the first measurement
        - withSecondLocationCount: Number of geo locations on the second measurement
     - Throws:
        - Some unspecified *CoreData* errors.
     */
    func assertV4(onContext context: NSManagedObjectContext, withFirstLocationCount firstLocationCount: Int, withSecondLocationCount secondLocationCount: Int) throws {
        let measurementFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Measurement")
        let sort = NSSortDescriptor(key: "identifier", ascending: false)
        measurementFetchRequest.sortDescriptors = [sort]
        let trackFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Track")
        let migratedMeasurements = try context.fetch(measurementFetchRequest)

        XCTAssertEqual(migratedMeasurements.count, 2)
        XCTAssertEqual(migratedMeasurements[0].primitiveValue(forKey: "identifier") as? Int64, Int64(2))
        XCTAssertEqual(migratedMeasurements[1].primitiveValue(forKey: "identifier") as? Int64, Int64(1))
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

    /**
     Assert a successful migration to a version 5 database.

     - Parameter onContext: The `NSManagedObjectContext` used to store the data to assert.
     - Throws:
        - Some unspecified *CoreData* errors.
     */
    func assertV5(onContext context: NSManagedObjectContext) throws {
        let measurementFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Measurement")
        let sort = NSSortDescriptor(key: "identifier", ascending: false)
        measurementFetchRequest.sortDescriptors = [sort]
        let migratedMeasurements = try context.fetch(measurementFetchRequest)

        XCTAssertEqual(migratedMeasurements.count, 2)
        XCTAssertEqual(migratedMeasurements[0].primitiveValue(forKey: "synchronizable") as? Bool, true)
        XCTAssertEqual(migratedMeasurements[1].primitiveValue(forKey: "synchronizable") as? Bool, true)
    }

    /**
    Assert a successful migration to a version 6 database.

    - Parameter onContext: The `NSManagedObjectContext` used to store the data to assert.
    - Throws:
        - Some unspecified *CoreData* errors.
     */
    func assertV6(onContext context: NSManagedObjectContext) throws {
        let geoLocationFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "GeoLocation")
        let migratedGeoLocations = try context.fetch(geoLocationFetchRequest)

        XCTAssertTrue(migratedGeoLocations[0].primitiveValue(forKey: "isPartOfCleanedTrack") as! Bool)
    }

    /**
     Assert a successful migration to a version 7 database.

     - Parameter onContext: The `NSManagedObjectContext` used to store the data to assert.
     - Throws:
        - Some unspecified *CoreData* errors.
    */
    func assertV7(onContext context: NSManagedObjectContext) throws {
        let measurementFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Measurement")
        let migratedMeasurements = try context.fetch(measurementFetchRequest)

        XCTAssertEqual(migratedMeasurements.count, 2)
        let events01 = (migratedMeasurements[0].value(forKey: "events") as! NSOrderedSet).array
        XCTAssertEqual(events01.count, 0)
        let events02 = (migratedMeasurements[1].value(forKey: "events") as! NSOrderedSet).array
        XCTAssertEqual(events02.count, 0)
    }

    func assertV10(onContext context: NSManagedObjectContext) throws {
        let measurementFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Measurement")
        let migratedMeasurements = try context.fetch(measurementFetchRequest)

        XCTAssertGreaterThan(migratedMeasurements.count, 0)
        // All the counts have been removed for this version.
        XCTAssertTrue(migratedMeasurements[0].entity.attributesByName.keys.filter {$0=="accelerationsCount"}.isEmpty)
        XCTAssertTrue(migratedMeasurements[0].entity.attributesByName.keys.filter {$0=="rotationsCount"}.isEmpty)
        XCTAssertTrue(migratedMeasurements[0].entity.attributesByName.keys.filter {$0=="directionsCount"}.isEmpty)
    }

    func assertV11(onContext context: NSManagedObjectContext) throws {
        let measurementFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Measurement")
        let migratedMeasurements = try context.fetch(measurementFetchRequest)
        // Timestamps on GeoLocation and Measurement should be proper Date instances now
        XCTAssertGreaterThan(migratedMeasurements.count, 0)
        XCTAssertTrue(migratedMeasurements[0].value(forKey: "time") is Date)
        // Now find the first `GeoLocation` and check it for having a proper `Date` as a timestamp.
        let tracks = try XCTUnwrap(migratedMeasurements[0].value(forKey: "tracks") as? NSOrderedSet)
        XCTAssertGreaterThan(tracks.count, 0)
        let firstTrack = try XCTUnwrap(tracks.firstObject as? NSManagedObject)
        let locations = try XCTUnwrap(firstTrack.value(forKey: "locations") as? NSOrderedSet)
        XCTAssertGreaterThan(locations.count, 0)
        let firstLocation = try XCTUnwrap(locations.firstObject as? NSManagedObject)
        XCTAssertTrue(firstLocation.value(forKey: "time") is Date)
    }

    /**
     Assert a successful migration to a Version 12 database.

     - Parameter onContext: The `NSManagedObjectContext` used to store the data to assert.
     - Throws:
        - Some unspecificed *CoreData* errors.
     */
    func assertV12(onContext context: NSManagedObjectContext) throws {
        // trackLength and isPartOfCleanedTrack should be gone
        let measurementFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Measurement")
        let migratedMeasurements = try context.fetch(measurementFetchRequest)

        XCTAssertEqual(migratedMeasurements.count, 2)
        XCTAssertTrue(migratedMeasurements[0].entity.attributesByName.keys.filter {$0=="trackLength"}.isEmpty)
        XCTAssertTrue(migratedMeasurements[0].entity.attributesByName.keys.filter {$0=="isPartOfCleanedTrack"}.isEmpty)
    }

    /**
     A test used to create an input data storeage file used by other tests. This is skipped since it is usually only required to run once when a new version of the Cyface data model is released.

     - Throws:
        - Unspecified *CoreData* errors on saving of the data model.
     */
    func skip_testExample() throws {
        let dataModelVersion = "11"
        let dataSetCreator = DataSetCreatorV11()

        let bundle = Bundle(for: DataMigrationTest.self)

        let migrator = CoreDataMigrator()
        let location = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let database = location.appendingPathComponent("V\(dataModelVersion)TestData").appendingPathExtension("sqlite")
        let container = loadContainer(from: "CyfaceModel", path: "DataCapturing_DataCapturing.bundle", with: dataModelVersion, at: database)
        try dataSetCreator.createData(in: container)

        for store in container.persistentStoreCoordinator.persistentStores {
            try container.persistentStoreCoordinator.remove(store)
        }
        migrator.forceWALCheckpointingForStore(at: database, inBundle: bundle)
        print("Written Version \(dataModelVersion) to \(location)!")
    }

    /**
     Loads an `NSPersistentContainer` with a model in a specific version from a store at the provided location inside the provided bundle.

     - Parameters:
        - from: The data model to load from
        - path: A subpath if the model is embedded within its bundle. To find out, please have a look at the actual location of your data model.
        - with: The version of the data model to load
        - at: The location of the storage file (usually an SQLite file
     - Returns: The loaded `NSPersistentContainer`
     */
    func loadContainer(from model: String, path: String, with version: String, at location: URL) -> NSPersistentContainer {
        let modelURL = Bundle(for: DataMigrationTest.self).url(forResource: "\(path)/\(model)", withExtension: "momd")
        let managedObjectModelBundle = Bundle(url: modelURL!)
        let managedObjectModelVersionURL = managedObjectModelBundle?.url(forResource: version, withExtension: "mom")

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
    }

}

extension FileManager {

    // MARK: - Temp

    /// Removes everything from the temporary directory.
    static func clearTempDirectoryContents() {
        guard let tmpDirectoryContents = try? FileManager.default.contentsOfDirectory(atPath: NSTemporaryDirectory()) else {
            fatalError()
        }
        tmpDirectoryContents.forEach {
            let fileURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent($0)
            try? FileManager.default.removeItem(atPath: fileURL.path)
        }
    }

    /**
     Moves the provided file to a temporary directory and provides a URL pointing to the new location.

     - Parameter filename: The name of the file to move
     - Returns: A `URL` pointing to the new files new location inside the temporary directory.
     */
    static func move(file filename: String, fromBundle bundle: Bundle, to: String = NSTemporaryDirectory()) -> URL {
        let destinationURL = URL(fileURLWithPath: to, isDirectory: true).appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: destinationURL)
        // The actual test bundle containing the relevant resources is bundled in some xctest meta bundle. To get the required files we need to unwrap that.
        let bundleURL = bundle.url(forResource: filename, withExtension: "sqlite")!
        do {
            try FileManager.default.copyItem(at: bundleURL, to: destinationURL)
        } catch {
            fatalError("""
            Unable to copy test data from \(bundleURL) to \(destinationURL).
            Reason: \(error)
            File Exists: \(FileManager.default.fileExists(atPath: bundleURL.absoluteString))
            """)
        }

        return destinationURL
    }
}

extension NSManagedObjectContext {

    // MARK: - Initializers

    /**
     Creates a `NSManagedObjectContext` based on its model and a store location. The file at the `storeURL` must of course be compatible with the provided `NSManagedObjectModel`.

     - Parameters:
        - model: The model to create the context for
        - storeURL: The URL of a store file compatible to the provided model. This will become the parent of this context.
     */
    convenience init(model: NSManagedObjectModel, storeURL: URL) {
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        do {
            try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
        } catch {
            fatalError("\(error)")
        }

        self.init(concurrencyType: .mainQueueConcurrencyType)

        self.persistentStoreCoordinator = persistentStoreCoordinator
    }

    // MARK: - Destroy

    /**
     Closes and destroyes all stores.
     */
    func destroyStore() {
        persistentStoreCoordinator?.persistentStores.forEach {
            ((try? persistentStoreCoordinator?.remove($0)) as ()??)
            ((try? persistentStoreCoordinator?.destroyPersistentStore(at: $0.url!, ofType: $0.type, options: nil)) as ()??)
        }
    }
}
