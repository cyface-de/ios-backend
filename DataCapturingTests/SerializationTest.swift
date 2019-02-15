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
@testable import DataCapturing

/**
 Tests whether serialization and deserialization into and from the Cyface Binary Format works as expected

 - Author: Klemens Muthmann
 - Version: 1.0.1
 - Since: 1.0.0
 */
class SerializationTest: XCTestCase {

    /// The object of the class under test
    var oocut: CyfaceBinaryFormatSerializer!
    /// A `PersistenceLayer` instance used to load and store data for testing purposes.
    var persistenceLayer: PersistenceLayer!
    /// A `MeasurementEntity` holding a test measurement to serialize and deserialize.
    var fixture: MeasurementEntity!

    override func setUp() {
        super.setUp()
        oocut = CyfaceBinaryFormatSerializer()

        let measurementCreationPromise = expectation(description: "Store fixture measurement!")
        do {
        persistenceLayer = try PersistenceLayer(withDistanceCalculator: DefaultDistanceCalculationStrategy()) { persistence, status in
            guard case .success = status, let persistence = persistence else {
                XCTFail("Unable to set up test since persistence layer could not be initialized!")
                return measurementCreationPromise.fulfill()
            }

            persistence.createMeasurement(at: 1, withContext: .bike) { measurement, status in
                guard case .success = status, let measurement = measurement else {
                    XCTFail("Unable to create measurement!")
                    return measurementCreationPromise.fulfill()
                }

                self.fixture = MeasurementEntity(identifier: measurement.identifier, context: MeasurementContext(rawValue: measurement.context!)!)
                persistence.save(locations: [GeoLocation(latitude: 1.0, longitude: 1.0, accuracy: 2.0, speed: 1.0, timestamp: 10_000), GeoLocation(latitude: 1.0, longitude: 1.0, accuracy: 2.0, speed: 1.0, timestamp: 10_100), GeoLocation(latitude: 1.0, longitude: 1.0, accuracy: 2.0, speed: 1.0, timestamp: 10_100)], toMeasurement: self.fixture!) { _, _ in
                    persistence.save(accelerations: [Acceleration(timestamp: 10_000, x: 1.0, y: 1.0, z: 1.0), Acceleration(timestamp: 10_100, x: 1.0, y: 1.0, z: 1.0), Acceleration(timestamp: 10_100, x: 1.0, y: 1.0, z: 1.0)], toMeasurement: self.fixture!) { _, _ in
                        measurementCreationPromise.fulfill()
                    }
                }
            }
        }
        } catch let error {
            XCTFail("Unable to set up test since persistence layer could not be initialized due to \(error.localizedDescription)!")
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    override func tearDown() {
        oocut = nil
        let tearDownPromise = expectation(description: "Delete the whole database.")
        persistenceLayer.delete { status in
            guard case .success = status else {
                fatalError()
            }

            tearDownPromise.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        super.tearDown()
    }

    /**
     Tests if serialization works for uncompressed data.
     */
    func testUncompressedSerialization() {
        var resCache: Data?
        let promise = expectation(description: "Unable to load measurement to serialize!")
        persistenceLayer.load(measurementIdentifiedBy: fixture.identifier) { measurement, status in
            guard case .success = status, let measurement = measurement else {
                XCTFail("Unable to load measurement!")
                return promise.fulfill()
            }

            do {
                resCache = try self.oocut.serialize(measurement)
            } catch {
                XCTFail("Unexpected error during measurement serialization")
            }
            promise.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)

        guard let res = resCache else {
            fatalError("SerializationTest.testUncompressedSerialization(): Unable to get result of serialization!")
        }

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
    }

    /**
     Tests if serialization works for compressed data.
     */
    func testCompressedSerialization() {
        var resCache: Data?
        let syncGroup = DispatchGroup()
        syncGroup.enter()
        persistenceLayer.load(measurementIdentifiedBy: fixture.identifier) { measurement, status in
            guard case .success = status, let measurement = measurement else {
                XCTFail("Unable to load measurement!")
                return syncGroup.leave()
            }

            do {
                resCache = try self.oocut.serializeCompressed(measurement)
            } catch {
                fatalError()
            }
            syncGroup.leave()
        }
        guard syncGroup.wait(timeout: DispatchTime.now() + .seconds(2)) == .success else {
            fatalError("SerializationTest.testCompressedSerialization(): Unable to get result of serialization!")
        }

        guard let res = resCache else {
            fatalError("SerializationTest.testCompressedSerialization(): Unable to get result of serialization!")
        }

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
    }

    /**
     Tests that geo location serialization works as expected for `GeoLocation` instances. This test runs isolated from all other serializations.
     */
    func testSerializeGeoLocations() {
        let measurementIdentifier = fixture.identifier
        let promise = expectation(description: "Unable to load measurement for serialization!")

        var timestamp: [UInt32] = []
        var accuracy: [UInt16] = []
        persistenceLayer.load(measurementIdentifiedBy: measurementIdentifier) { measurement, status in
            guard case .success = status, let measurement = measurement else {
                XCTFail("Unable to load measurement!")
                return promise.fulfill()
            }

            let locations = measurement.geoLocations
            do {
                let serializedData = try self.oocut.serialize(measurement)
                let sizeOfHeaderInBytes = 18
                let sizeOfOneGeoLocationInBytes = 36

                for index in 0..<locations!.count {
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
                promise.fulfill()
            } catch {
                XCTFail("Unable to serialize measurement \(measurement.identifier).")
            }
        }

        waitForExpectations(timeout: 10, handler: nil)
        //print("test")
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
