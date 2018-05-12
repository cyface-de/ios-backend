//
//  PersistenceTests.swift
//  DataCapturingTests
//
//  Created by Team Cyface on 06.03.18.
//  Copyright © 2018 Cyface GmbH. All rights reserved.
//

import XCTest
@testable import DataCapturing

class PersistenceTests: XCTestCase {

    var oocut: PersistenceLayer?
    var fixture: MeasurementEntity?

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let oocut = PersistenceLayer()

        let fixture = oocut.createMeasurement(at: 10_000)
        oocut.syncSave(toMeasurement: fixture, location: GeoLocation(latitude: 1.0, longitude: 1.0, accuracy: 1.0, speed: 1.0, timestamp: 10_000), accelerations: [Acceleration(timestamp: 10_000, x: 1.0, y: 1.0, z: 1.0)])
        oocut.syncSave(toMeasurement: fixture, location: GeoLocation(latitude: 1.0, longitude: 1.0, accuracy: 1.0, speed: 1.0, timestamp: 10_001), accelerations: [Acceleration(timestamp: 10_001, x: 1.0, y: 1.0, z: 1.0), Acceleration(timestamp: 10_002, x: 1.0, y: 1.0, z: 1.0)])

            self.oocut = oocut
            self.fixture = fixture
    }

    override func tearDown() {
        oocut?.syncDelete()
        oocut = nil
        fixture = nil
        super.tearDown()
    }

    /**
     Tests if new measurements are created with the correct identifier and if identifiers are increased for each new measurement. This should even work if one measurement is deleted in between.
     */
    func testCreateMeasurement() {
        guard let secondMeasurement = oocut?.createMeasurement(at: 10_001) else {
            fatalError()
        }
        guard let firstMeasurement = fixture else {
            fatalError()
        }

        let secondMeasurementIdentifier = secondMeasurement.identifier
        XCTAssertEqual(secondMeasurementIdentifier, firstMeasurement.identifier+1)

        oocut!.syncDelete(measurement: secondMeasurement)

        guard let thirdMeasurement = oocut?.createMeasurement(at: 10_002) else {
            fatalError()
        }

        XCTAssertEqual(thirdMeasurement.identifier, secondMeasurementIdentifier+1)
    }

    func testCleanMeasurement() {
        guard let measurement = fixture else {
            XCTFail("Unable to unwrap test fixture!")
            return
        }

        guard let oocut = oocut else {
            XCTFail("Unable to unwrap object of class under test!")
            return
        }

        var accelerationCount: Int?
        var geoLocationCount: Int?

        let syncGroup = DispatchGroup()
        syncGroup.enter()
        oocut.load(measurementIdentifiedBy: measurement.identifier) { (measurementMo) in
            accelerationCount = measurementMo.accelerations!.count
            geoLocationCount = measurementMo.geoLocations!.count
            syncGroup.leave()
        }

        guard syncGroup.wait(timeout: DispatchTime.now() + .seconds(2)) == .success else {
            fatalError()
        }

        XCTAssertEqual(accelerationCount!, 3)
        XCTAssertEqual(geoLocationCount!, 2)

        syncGroup.enter()
        oocut.clean(measurement: measurement) {
            syncGroup.leave()
        }

        guard syncGroup.wait(timeout: DispatchTime.now() + .seconds(2)) == .success else {
            fatalError()
        }

        var accelerationsIsEmpty = false
        var geoLocationsIsEmpty = false

        syncGroup.enter()
        let loadedMeasurement = oocut.load(measurementIdentifiedBy: measurement.identifier) { measurementMo in
            accelerationsIsEmpty = measurementMo.accelerations!.isEmpty
            geoLocationsIsEmpty = measurementMo.geoLocations!.isEmpty
            syncGroup.leave()
        }

        guard syncGroup.wait(timeout: DispatchTime.now() + .seconds(2)) == .success else {
            fatalError()
        }

        XCTAssertTrue(accelerationsIsEmpty, "Accelerations have not been empty after cleaning!")
        XCTAssertTrue(!geoLocationsIsEmpty, "Geo Locations was empty after cleaning!")
    }

    func testDeleteMeasurement() {
        guard let fixture = fixture else {
            fatalError("PersistenceTests.testDeleteMeasurement(): Unable to unwrap test fixture!")
        }

        guard let oocut = oocut else {
            fatalError("PersistenceTests.testDeleteMeasurement(): Unable to unwrap object of class under test!")
        }

        let countOfMeasurementsBeforeDeletion = oocut.syncCountMeasurements()
        XCTAssertEqual(countOfMeasurementsBeforeDeletion, 1, "There should be one measurement before deleting it! There have been \(countOfMeasurementsBeforeDeletion).")

        oocut.syncDelete(measurement: fixture)

        let countOfMeasurementsAfterDeletion = oocut.syncCountMeasurements()
        XCTAssertEqual(countOfMeasurementsAfterDeletion, 0, "There should be no measurement after deleting it! There where \(countOfMeasurementsAfterDeletion).")
    }
}
