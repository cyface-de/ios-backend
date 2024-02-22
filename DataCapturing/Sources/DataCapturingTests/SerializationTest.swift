/*
 * Copyright 2018 - 2022 Cyface GmbH
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
@testable import DataCapturing

/**
 Tests whether serialization and deserialization into and from the Cyface Binary Format works as expected

 - Author: Klemens Muthmann
 - Version: 1.1.4
 - Since: 1.0.0
 */
class SerializationTest: XCTestCase {

    /// The object of the class under test
    var oocut: MeasurementSerializer!
    /// A `PersistenceLayer` instance used to load and store data for testing purposes.
    var persistenceLayer: CoreDataPersistenceLayer!
    /// A manager for handling the CoreData stack.
    var coreDataStack: CoreDataStack!
    /// The `NSManagedObjectModel` used by the test.
    static let dataModel = try! CoreDataStack.load(bundle: XCTestCase.appBundle()!)

    /// Initializes the test data set and `PersistenceLayer` with some test data.
    override func setUp() async throws {
        try await super.setUp()
        oocut = MeasurementSerializer()
        let expectation = self.expectation(description: "CoreDataStack started successfully.")

        coreDataStack = CoreDataStack(storeType: NSInMemoryStoreType, migrator: CoreDataMigrator(), modelName: "CyfaceModel", model: SerializationTest.dataModel, bundle: XCTestCase.appBundle()!)
        let bundle = Bundle(for: type(of: coreDataStack))

        try await coreDataStack.setup()
        persistenceLayer = (self.coreDataStack.persistenceLayer() as! CoreDataPersistenceLayer)
    }

    /// Finalizes the test environment by deleting all test data.
    override func tearDownWithError() throws {
        oocut = nil
        try persistenceLayer.delete()
        coreDataStack = nil
        try super.tearDownWithError()
    }

    /// Store a test fixture to CoreData and provide the measurement identifier.
    func fixture() throws -> UInt64 {
        var measurement = try self.persistenceLayer.createMeasurement(at: Date(), inMode: "BICYCLE")
        try self.persistenceLayer.appendNewTrack(to: &measurement)

        try self.persistenceLayer.save(locations: [TestFixture.location(accuracy: 2.0, timestamp: Date(timeIntervalSince1970: 10.0)), TestFixture.location(accuracy: 2.0, timestamp: Date(timeIntervalSince1970: 10.1)), TestFixture.location(accuracy: 2.0, timestamp: Date(timeIntervalSince1970: 10.2))], in: &measurement)
        try self.persistenceLayer.save(
            accelerations: [
                SensorValue(timestamp: Date(timeIntervalSince1970: 10.0), x: 1.0, y: 1.0, z: 1.0),
                SensorValue(timestamp: Date(timeIntervalSince1970: 10.1), x: 1.0, y: 1.0, z: 1.0),
                SensorValue(timestamp: Date(timeIntervalSince1970: 10.2), x: 1.0, y: 1.0, z: 1.0)
            ],
            in: &measurement
        )

        return measurement.identifier
    }

    /// Tests if serialization of a simple empty measurement into the Cyface binary format works as expected.
    func testSerializeEmptyMeasurement() throws {
        let measurement = FinishedMeasurement(identifier: 1)
        measurement.tracks = []
        let res = try oocut.serialize(serializable: measurement)

        let deserializedMeasurement = try De_Cyface_Protos_Model_Measurement(serializedData: res[2...])

        XCTAssertTrue(deserializedMeasurement.locationRecords.timestamp.isEmpty)
        XCTAssertFalse(deserializedMeasurement.hasAccelerationsBinary)
        XCTAssertFalse(deserializedMeasurement.hasCapturingLog)
        XCTAssertFalse(deserializedMeasurement.hasDirectionsBinary)
        XCTAssertFalse(deserializedMeasurement.hasRotationsBinary)
    }

    /**
     Tests if serialization works for uncompressed data.
     */
    func testUncompressedSerialization() {
        do {
            let measurement = try persistenceLayer.load(measurementIdentifiedBy: fixture())
            let res = try oocut.serialize(serializable: measurement)

            let deserializedMeasurement = try De_Cyface_Protos_Model_Measurement(serializedData: res[2...])
            assert(fixture: deserializedMeasurement)

        } catch {
            XCTFail("Error \(error.localizedDescription)")
        }
    }

    /**
     Tests if serialization works for compressed data.
     */
    func testCompressedSerialization() {
        do {
            let measurement = try persistenceLayer.load(measurementIdentifiedBy: fixture())
            let res = try oocut.serializeCompressed(serializable: measurement)

            let uncompressedData = res.inflate()
            guard let uncompressedData = uncompressedData else {
                return XCTFail("Error unpacking zipped measurement!")
            }

            assert(fixture: try De_Cyface_Protos_Model_Measurement(serializedData: uncompressedData[2...]))
        } catch {
            XCTFail("Error \(error.localizedDescription)")
        }
    }

    /// Assert the deserialized test fixture.
    ///
    /// - see: `SerializationTest.fixture()`
    private func assert(fixture:De_Cyface_Protos_Model_Measurement) {
        XCTAssertFalse(fixture.hasRotationsBinary)
        XCTAssertFalse(fixture.hasCapturingLog)
        XCTAssertFalse(fixture.hasDirectionsBinary)
        XCTAssertTrue(fixture.hasLocationRecords)
        XCTAssertTrue(fixture.hasAccelerationsBinary)

        XCTAssertEqual(fixture.locationRecords.timestamp.count, 3)
        XCTAssertEqual(fixture.locationRecords.timestamp[0], 10_000)
        XCTAssertEqual(fixture.locationRecords.timestamp[1], 100)
        XCTAssertEqual(fixture.locationRecords.timestamp[2], 100)
        XCTAssertEqual(fixture.locationRecords.longitude[0], 2000000)
        XCTAssertEqual(fixture.locationRecords.longitude[1], 0)
        XCTAssertEqual(fixture.locationRecords.longitude[2], 0)

        XCTAssertEqual(fixture.accelerationsBinary.accelerations.count, 1)
        let firstAccelerationsBatch = fixture.accelerationsBinary.accelerations[0]
        XCTAssertEqual(firstAccelerationsBatch.timestamp.count, 3)
        XCTAssertEqual(firstAccelerationsBatch.timestamp[0], 10_000)
        XCTAssertEqual(firstAccelerationsBatch.timestamp[1], 100)
        XCTAssertEqual(firstAccelerationsBatch.timestamp[2], 100)

        XCTAssertEqual(fixture.events.count, 1)
    }

    /**
     This creates a really big test data set usable to test programs unpacking such a set. This test is skipped since it takes really long.
     */
    func ignore_testSerializeBigDataSet() throws {
        let nextIdentifier = try persistenceLayer.nextIdentifier()
        let measurement = try FakeMeasurementImpl.fakeMeasurement(
            identifier: nextIdentifier)
            .addGeoLocations(countOfGeoLocations: 36_000)
            .addAccelerations(countOfAccelerations: 3_600_000)
            .build(persistenceLayer
            )
        _ = try oocut.serialize(serializable: measurement)
    }
}
