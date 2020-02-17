/*
 * Copyright 2018 Cyface GmbH
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
 - Version: 1.1.1
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

    /// Initializes the test data set and `PersistenceLayer` with some test data.
    override func setUp() {
        super.setUp()
        oocut = MeasurementSerializer()

        do {
            guard let bundle = Bundle(identifier: "de.cyface.DataCapturing") else {
                fatalError()
            }
            coreDataStack = CoreDataManager(storeType: NSInMemoryStoreType, migrator: CoreDataMigrator())
            coreDataStack.setup(bundle: bundle)
            persistenceLayer = PersistenceLayer(onManager: coreDataStack)
            persistenceLayer.context = persistenceLayer.makeContext()
            let measurement = try persistenceLayer.createMeasurement(at: 1, inMode: "BICYCLE")
            persistenceLayer.appendNewTrack(to: measurement)

            fixture = measurement.identifier
            try persistenceLayer.save(locations: [GeoLocation(latitude: 1.0, longitude: 1.0, accuracy: 2.0, speed: 1.0, timestamp: 10_000, isValid: true), GeoLocation(latitude: 1.0, longitude: 1.0, accuracy: 2.0, speed: 1.0, timestamp: 10_100, isValid: true), GeoLocation(latitude: 1.0, longitude: 1.0, accuracy: 2.0, speed: 1.0, timestamp: 10_100, isValid: true)], in: measurement)
            try persistenceLayer.save(accelerations: [SensorValue(timestamp: Date(timeIntervalSince1970: 10_000.0), x: 1.0, y: 1.0, z: 1.0), SensorValue(timestamp: Date(timeIntervalSince1970: 10_100.0), x: 1.0, y: 1.0, z: 1.0), SensorValue(timestamp: Date(timeIntervalSince1970: 10_100.0), x: 1.0, y: 1.0, z: 1.0)], in: measurement)

        } catch let error {
            XCTFail("Unable to set up test since persistence layer could not be initialized due to \(error.localizedDescription)!")
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

    /**
     Tests if serialization works for uncompressed data.
     */
    func testUncompressedSerialization() {
        do {
            let measurement = try persistenceLayer.load(measurementIdentifiedBy: fixture)
            let res = try oocut.serialize(serializable: measurement)

            XCTAssertEqual(res.count, 222)
            // Data Format Version
            XCTAssertEqual(res[0], 0)
            XCTAssertEqual(res[1], 1)
            // Count of Geo Locations
            XCTAssertEqual(res[2], 0)
            XCTAssertEqual(res[3], 0)
            XCTAssertEqual(res[4], 0)
            XCTAssertEqual(res[5], 3)
            // Count of Accelerations
            XCTAssertEqual(res[9], 3)
        } catch let error {
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

            XCTAssertEqual(uncompressedData?.count, 222)
            // Data Format Version
            XCTAssertEqual(uncompressedData![0], 0)
            XCTAssertEqual(uncompressedData![1], 1)
            // Count of Geo Locations
            XCTAssertEqual(uncompressedData![2], 0)
            XCTAssertEqual(uncompressedData![3], 0)
            XCTAssertEqual(uncompressedData![4], 0)
            XCTAssertEqual(uncompressedData![5], 3)
            // Count of Accelerations
            XCTAssertEqual(uncompressedData![9], 3)
        } catch let error {
            XCTFail("Error \(error)")
        }
    }

    /**
     This creates a really big test data set usable to test programs unpacking such a set. This test is skipped since it takes really long.
     */
    func skip_testSerializeBigDataSet() throws {
        let measurement = try FakeMeasurementImpl.fakeMeasurement(persistenceLayer: persistenceLayer).appendTrackAnd().addGeoLocationsAnd(countOfGeoLocations: 36_000).addAccelerations(countOfAccelerations: 3_600_000).build()
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
            XCTAssert(timestamp.count == 3)
            XCTAssert(timestamp[0] == 10_000)
            XCTAssert(timestamp[1] == 10_100)
            XCTAssert(timestamp[2] == 10_100)

            XCTAssert(accuracy.count == 3)
            XCTAssert(accuracy[0] == 200)
            XCTAssert(accuracy[1] == 200)
            XCTAssert(accuracy[2] == 200)
        } catch let error {
            XCTFail("Unable to serialize measurement \(fixture). Error \(error)")
        }
    }

    /// Tests that serialization to an events file works as expected
    func testEventSerialization_HappyPath() throws {
        // Arrange
        let measurement = try persistenceLayer.load(measurementIdentifiedBy: fixture)

        guard let events = measurement.events?.array as? [Event] else {
            fatalError()
        }

        let eventsSerializer = EventsSerializer()

        // Act
        let eventsData = try eventsSerializer.serialize(serializable: events)

        // Assert
        let sizeOfHeaderInBytes = 6
        let sizeOfOneEventWithoutValue = 12
        let sizeOfBicycleValue = 7

        XCTAssertEqual(eventsData.count, sizeOfHeaderInBytes + events.count * sizeOfOneEventWithoutValue + sizeOfBicycleValue)
    }

    /**
     Converts some byte data to an `UInt32` value. This is used to deserialize and thus test the success of serialization.

     - Parameter data: The data to convert.
     - Returns: The provided data interpreted as `UInt32`.
     */
    func dataToUInt32(data: [UInt8]) -> UInt32 {
        var value: UInt32 = 0
        for byte in data {
            value = value << 8
            value = value | UInt32(byte)
        }
        return value
    }

    /**
     Converts some byte data to an `UInt16` value. This is used to deserialize and thus test the success of serialization.

     - Parameter data: The data to convert.
     - Returns: The provided data interpreted as `UInt16`.
     */
    func dataToUInt16(data: [UInt8]) -> UInt16 {
        var value: UInt16 = 0
        for byte in data {
            value = value << 8
            value = value | UInt16(byte)
        }
        return value
    }
}
