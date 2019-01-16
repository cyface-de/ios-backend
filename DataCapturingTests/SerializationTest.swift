//
//  SerializationTest.swift
//  DataCapturing-Unit-Tests
//
//  Created by Team Cyface on 01.03.18.
//

import XCTest
@testable import DataCapturing

class SerializationTest: XCTestCase {

    var oocut: CyfaceBinaryFormatSerializer!
    var persistenceLayer: PersistenceLayer!
    var fixture: MeasurementEntity!

    override func setUp() {
        super.setUp()
        oocut = CyfaceBinaryFormatSerializer()
        let syncGroup = DispatchGroup()
        syncGroup.enter()
        persistenceLayer = PersistenceLayer {
            syncGroup.leave()
        }
        guard syncGroup.wait(timeout: DispatchTime.now() + .seconds(2)) == .success else {
            fatalError("Unable to initialize persistence layer.")
        }

        fixture = persistenceLayer.createMeasurement(at: 1, withContext: .bike)
        persistenceLayer.syncSave(locations: [GeoLocation(latitude: 1.0, longitude: 1.0, accuracy: 2.0, speed: 1.0, timestamp: 10_000), GeoLocation(latitude: 1.0, longitude: 1.0, accuracy: 2.0, speed: 1.0, timestamp: 10_100), GeoLocation(latitude: 1.0, longitude: 1.0, accuracy: 2.0, speed: 1.0, timestamp: 10_100)], accelerations: [Acceleration(timestamp: 10_000, x: 1.0, y: 1.0, z: 1.0), Acceleration(timestamp: 10_100, x: 1.0, y: 1.0, z: 1.0), Acceleration(timestamp: 10_100, x: 1.0, y: 1.0, z: 1.0)], toMeasurement: fixture)
    }

    override func tearDown() {
        oocut = nil
        super.tearDown()
    }

    func testUncompressedSerialization() {
        var resCache: Data?
        let promise = expectation(description: "Unable to load measurement to serialize!")
        persistenceLayer.load(measurementIdentifiedBy: fixture.identifier) { (measurement) in
            /* debugPrint("===================================================")
            debugPrint("Geo Locations: \(measurement.geoLocations?.count).")
            debugPrint("Accelerations: \(measurement.accelerations?.count).")
            debugPrint("===================================================") */
            resCache = self.oocut.serialize(measurement)
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

    func testCompressedSerialization() {
        var resCache: Data?
        let syncGroup = DispatchGroup()
        syncGroup.enter()
        persistenceLayer.load(measurementIdentifiedBy: fixture.identifier) { (measurement) in
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

    func testSerializeGeoLocations() {
        let measurementIdentifier = fixture.identifier
        let promise = expectation(description: "Unable to load measurement for serialization!")

        var timestamp: [UInt32] = []
        var accuracy: [UInt16] = []
        persistenceLayer.load(measurementIdentifiedBy: measurementIdentifier) { (measurement) in
            let locations = measurement.geoLocations
            let serializedData = self.oocut.serialize(measurement)

            for index in 0..<locations.count {
                let indexOffset = index * 36 // width of one geo location
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
            promise.fulfill()
            XCTAssert(timestamp.count == 3)
            XCTAssert(timestamp[0] == 10_000)
            XCTAssert(timestamp[1] == 10_100)
            XCTAssert(timestamp[2] == 10_100)

            XCTAssert(accuracy.count == 3)
            XCTAssert(accuracy[0] == 200)
            XCTAssert(accuracy[1] == 200)
            XCTAssert(accuracy[2] == 200)
        }

        waitForExpectations(timeout: 10, handler: nil)
        //print("test")
    }

    func dataToUInt32(data: [UInt8]) -> UInt32 {
        var value: UInt32 = 0
        for byte in data {
            value = value << 8
            value = value | UInt32(byte)
        }
        return value
    }

    func dataToUInt16(data: [UInt8]) -> UInt16 {
        var value: UInt16 = 0
        for byte in data {
            value = value << 8
            value = value | UInt16(byte)
        }
        return value
    }
}
