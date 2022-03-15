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
 - Version: 1.1.3
 - Since: 1.0.0
 */
class SerializationTest: XCTestCase {

    /// The object of the class under test
    var oocut: MeasurementSerializer!
    /// A `PersistenceLayer` instance used to load and store data for testing purposes.
    var persistenceLayer: PersistenceLayer!
    /// A `MeasurementEntity` holding a test measurement to serialize and deserialize.
    var fixture: Int64!
    /// A manager for handling the CoreData stack.
    var coreDataStack: CoreDataManager!
    /// The `NSManagedObjectModel` used by the test.
    static let dataModel = try! CoreDataManager.load()

    /// Initializes the test data set and `PersistenceLayer` with some test data.
    override func setUp() {
        super.setUp()
        oocut = MeasurementSerializer()
        let expectation = self.expectation(description: "CoreDataStack started successfully.")
        var setUpError:Error?

        do {
            coreDataStack = CoreDataManager(storeType: NSInMemoryStoreType, migrator: CoreDataMigrator(), modelName: "CyfaceModel", model: SerializationTest.dataModel)
            let bundle = Bundle(for: type(of: coreDataStack))

            try coreDataStack.setup(bundle: bundle) { [weak self] (error) in
                if let error = error {
                    setUpError = error
                    return XCTFail("Unable to setup CoreData stack due to \(error)")
                }

                guard let self = self else {
                    return
                }

                do {
                    self.persistenceLayer = PersistenceLayer(onManager: self.coreDataStack)
                    var measurement = try self.persistenceLayer.createMeasurement(at: 1, inMode: "BICYCLE")
                    try self.persistenceLayer.appendNewTrack(to: &measurement)

                    self.fixture = measurement.identifier
                    try self.persistenceLayer.save(locations: [TestFixture.location(accuracy: 2.0, timestamp: Date(timeIntervalSince1970: 10.0)), TestFixture.location(accuracy: 2.0, timestamp: Date(timeIntervalSince1970: 10.1)), TestFixture.location(accuracy: 2.0, timestamp: Date(timeIntervalSince1970: 10.2))], in: &measurement)
                    try self.persistenceLayer.save(accelerations: [SensorValue(timestamp: Date(timeIntervalSince1970: 10.0), x: 1.0, y: 1.0, z: 1.0), SensorValue(timestamp: Date(timeIntervalSince1970: 10.1), x: 1.0, y: 1.0, z: 1.0), SensorValue(timestamp: Date(timeIntervalSince1970: 10.2), x: 1.0, y: 1.0, z: 1.0)], in: &measurement)

                } catch {
                    setUpError = error
                    XCTFail("Unable to set up test since persistence layer could not be initialized due to \(error.localizedDescription)!")
                }
                expectation.fulfill()
            }
        } catch {
            XCTFail("Unable to setup CoreData stack due to \(error.localizedDescription).")
        }
        
        wait(for: [expectation],timeout: 5.0)
        if let error = setUpError {
            XCTFail("Unable to setup SerializationTest \(error.localizedDescription)")
        }
    }

    /// Finalizes the test environment by deleting all test data.
    override func tearDown() {
        oocut = nil
        do {
            try persistenceLayer.delete()
        } catch {
            fatalError()
        }
        coreDataStack = nil
        super.tearDown()
    }

    func testSerializeSensorValues() throws {
        let sensorValueSerializer = SensorValueSerializer()

        // 1
        let firstBatch = try sensorValueSerializer.serialize(serializable: [SensorValue(timestamp: Date(timeIntervalSince1970: 10.000), x: 1.0, y: 1.0, z: 1.0), SensorValue(timestamp: Date(timeIntervalSince1970: 10.100), x: 1.1, y: 1.1, z: 1.1), SensorValue(timestamp: Date(timeIntervalSince1970: 10.200), x: -2.0, y: -2.0, z: -2.0)])

        // 2
        let secondBatch = try sensorValueSerializer.serialize(serializable: [SensorValue(timestamp: Date(timeIntervalSince1970: 10.300), x: 1.5, y: 1.5, z: 1.5), SensorValue(timestamp: Date(timeIntervalSince1970: 10.400), x: 1.2, y: 1.2, z: 1.2)])

        // 3
        var data = Data()
        data.append(contentsOf: firstBatch)
        data.append(contentsOf: secondBatch)


        // 4
        var measurementBytes = De_Cyface_Protos_Model_MeasurementBytes()
        measurementBytes.formatVersion = 2
        measurementBytes.accelerationsBinary = data

        let deserializedMeasurement = try De_Cyface_Protos_Model_Measurement(serializedData: measurementBytes.serializedData())

        XCTAssertEqual(deserializedMeasurement.accelerationsBinary.accelerations[0].z[0], 1000)
        XCTAssertEqual(deserializedMeasurement.accelerationsBinary.accelerations[0].z[1], 100)
        XCTAssertEqual(deserializedMeasurement.accelerationsBinary.accelerations[0].z[2], -3100)
        XCTAssertEqual(deserializedMeasurement.accelerationsBinary.accelerations[0].timestamp[0],10_000)
        XCTAssertEqual(deserializedMeasurement.accelerationsBinary.accelerations[0].timestamp[1],100)
        XCTAssertEqual(deserializedMeasurement.accelerationsBinary.accelerations[0].timestamp[2],100)
    }

    func testSerializeEmptyMeasurement() throws {
        let measurement = MeasurementMO(context: self.persistenceLayer.makeContext())
        measurement.tracks = []
        let res = try oocut.serialize(serializable: measurement)

        let deserializedMeasurement = try De_Cyface_Protos_Model_Measurement(serializedData: res)

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
            let measurement = try persistenceLayer.load(measurementIdentifiedBy: fixture)
            let res = try oocut.serialize(serializable: measurement)

            let deserializedMeasurement = try De_Cyface_Protos_Model_Measurement(serializedData: res)
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
            let measurement = try persistenceLayer.load(measurementIdentifiedBy: fixture)
            let res = try oocut.serializeCompressed(serializable: measurement)

            let uncompressedData = res.inflate()
            guard let uncompressedData = uncompressedData else {
                return XCTFail("Error unpacking zipped measurement!")
            }

            assert(fixture: try De_Cyface_Protos_Model_Measurement(serializedData: uncompressedData))
        } catch {
            XCTFail("Error \(error.localizedDescription)")
        }
    }

    private func assert(fixture:De_Cyface_Protos_Model_Measurement) {
        XCTAssertFalse(fixture.hasRotationsBinary)
        XCTAssertFalse(fixture.hasCapturingLog)
        XCTAssertFalse(fixture.hasDirectionsBinary)
        XCTAssertTrue(fixture.hasLocationRecords)
        XCTAssertTrue(fixture.hasAccelerationsBinary)

        XCTAssertEqual(fixture.locationRecords.timestamp.count, 3)
        XCTAssertEqual(fixture.locationRecords.timestamp[0], 10_000)
        XCTAssertEqual(fixture.locationRecords.timestamp[1], 100)
        XCTAssertEqual(fixture.locationRecords.timestamp[2], 0)
        XCTAssertEqual(fixture.locationRecords.longitude[0], 1000000)
        XCTAssertEqual(fixture.locationRecords.longitude[1], 0)
        XCTAssertEqual(fixture.locationRecords.longitude[2], 0)

        XCTAssertEqual(fixture.accelerationsBinary.accelerations.count, 1)
        let firstAccelerationsBatch = fixture.accelerationsBinary.accelerations[0]
        XCTAssertEqual(firstAccelerationsBatch.timestamp.count, 3)
        XCTAssertEqual(firstAccelerationsBatch.timestamp[0], 10_000)
        XCTAssertEqual(firstAccelerationsBatch.timestamp[1], 100)
        XCTAssertEqual(firstAccelerationsBatch.timestamp[2], 0)

        XCTAssertEqual(fixture.events.count, 3)
    }

    /**
     This creates a really big test data set usable to test programs unpacking such a set. This test is skipped since it takes really long.
     */
    func ignore_testSerializeBigDataSet() throws {
        let nextIdentifier = try persistenceLayer.nextIdentifier()
        let measurement = try FakeMeasurementImpl.fakeMeasurement(identifier: nextIdentifier).appendTrackAnd().addGeoLocationsAnd(countOfGeoLocations: 36_000).addAccelerations(countOfAccelerations: 3_600_000).build(persistenceLayer)
        let data = try oocut.serialize(serializable: measurement)
        try data.write(to: URL(fileURLWithPath: "/Users/cyface/data.cyf"))
    }

    /**
     Tests that geo location serialization works as expected for `GeoLocation` instances. This test runs isolated from all other serializations.
     */
    func testSerializeGeoLocations() {
        var timestamp: [UInt32] = []
        var accuracy: [UInt16] = []
        do {
            let measurement = try persistenceLayer.load(measurementIdentifiedBy: fixture)

            let locations = try PersistenceLayer.collectGeoLocations(from: measurement)

            let serializedData = try self.oocut.serialize(serializable: measurement)
            let sizeOfHeaderInBytes = 18
            let sizeOfOneGeoLocationInBytes = 36

            for index in 0..<locations.count {
                let indexOffset = index * sizeOfOneGeoLocationInBytes + sizeOfHeaderInBytes
                let timestampStartIndex = indexOffset
                let timestampEndIndex = indexOffset + 8
                let timestampData = serializedData[timestampStartIndex..<timestampEndIndex]
                let accuracyStartIndex = indexOffset + 32
                let accuracyEndIndex = indexOffset + 36
                let accuracyData = serializedData[accuracyStartIndex..<accuracyEndIndex]
                timestamp.append(self.dataToUInt32(data: Array(timestampData)))
                accuracy.append(self.dataToUInt16(data: Array(accuracyData)))
            }

            //print(serializedData.map { String(format: "%02x", $0) }.joined())
            XCTAssertEqual(timestamp.count, 3)
            XCTAssertEqual(timestamp[0], 10_000)
            XCTAssertEqual(timestamp[1], 10_100)
            XCTAssertEqual(timestamp[2], 10_200)

            XCTAssertEqual(accuracy.count, 3)
            XCTAssertEqual(accuracy[0], 200)
            XCTAssertEqual(accuracy[1], 200)
            XCTAssertEqual(accuracy[2], 200)
        } catch let error {
            XCTFail("Unable to serialize measurement \(String(describing: fixture)). Error \(error)")
        }
    }
}
