//
//  SerializationTest.swift
//  DataCapturing-Unit-Tests
//
//  Created by Team Cyface on 01.03.18.
//

import XCTest
@testable import DataCapturing

class SerializationTest: XCTestCase {

    var oocut: CyfaceBinaryFormatSerializer?
    var persistenceLayer: PersistenceLayer?
    var fixture: MeasurementEntity?

    override func setUp() {
        super.setUp()
        oocut = CyfaceBinaryFormatSerializer()
        persistenceLayer = PersistenceLayer()

        fixture = persistenceLayer!.createMeasurement(at: 1)
        persistenceLayer!.syncSave(toMeasurement: fixture!, location: GeoLocation(latitude: 1.0, longitude: 1.0, accuracy: 2.0, speed: 1.0, timestamp: 10_000), accelerations: [Acceleration(timestamp: 10_000, x: 1.0, y: 1.0, z: 1.0)])
        persistenceLayer!.syncSave(toMeasurement: fixture!, location: GeoLocation(latitude: 1.0, longitude: 1.0, accuracy: 2.0, speed: 1.0, timestamp: 10_100), accelerations: [Acceleration(timestamp: 10_100, x: 1.0, y: 1.0, z: 1.0)])
        persistenceLayer!.syncSave(toMeasurement: fixture!, location: GeoLocation(latitude: 1.0, longitude: 1.0, accuracy: 2.0, speed: 1.0, timestamp: 10_100), accelerations: [Acceleration(timestamp: 10_100, x: 1.0, y: 1.0, z: 1.0)])
    }

    override func tearDown() {
        oocut = nil
        super.tearDown()
    }

    func testUncompressedSerialization() {
        guard let oocut = oocut else {
            fatalError("SerializationTest.testUncompressedSerialization(): Test failed! No object of class under test.")
        }
        guard let pl = persistenceLayer else {
            fatalError("SerializationTest.testUncompressedSerialization(): Test failed! No persistence layer to create test fixture from.")
        }

        guard let fixture = fixture else {
            fatalError("SerializationTest.testUncompressedSerialization(): Test failed! No test fixture!")
        }

        var resCache: Data?
        let syncGroup = DispatchGroup()
        syncGroup.enter()
        pl.load(measurementIdentifiedBy: fixture.identifier) { (measurement) in
            debugPrint("===================================================")
            debugPrint("Geo Locations: \(measurement.geoLocations?.count).")
            debugPrint("Accelerations: \(measurement.accelerations?.count).")
            debugPrint("===================================================")
            resCache = oocut.serialize(measurement)
            syncGroup.leave()
        }

        guard syncGroup.wait(timeout: DispatchTime.now() + .seconds(2)) == .success else {
            fatalError("SerializationTest.testUncompressedSerialization(): Unable to serialize fixture!")
        }

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
        guard let oocut = oocut else {
            fatalError("erializationTest.testCompressedSerialization(): Test failed! No object of class under test.")
        }
        guard let pl = persistenceLayer else {
            fatalError("erializationTest.testCompressedSerialization(): Test failed! No persistence layer to create test fixture from.")
        }

        guard let fixture = fixture else {
            fatalError("SerializationTest.testCompressedSerialization(): Test failed! No test fixture!")
        }

        var resCache: Data?
        let syncGroup = DispatchGroup()
        syncGroup.enter()
        pl.load(measurementIdentifiedBy: fixture.identifier) { (measurement) in
            resCache = oocut.serializeCompressed(measurement)
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
}
