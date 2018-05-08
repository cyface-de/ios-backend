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
    var fixture: MeasurementMO?
    var fixtureIdentifier: Int64?
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let oocut = PersistenceLayer()

        let fixture = oocut.createMeasurement(at: 10_000)
        let fixture2 = oocut.createMeasurement2(at: 10_000)
        fixtureIdentifier = fixture2.identifier
        /*fixture.synchronized = false
        fixture.addToGeoLocations(oocut.createGeoLocation(latitude: 1.0, longitude: 1.0, accuracy: 1.0, speed: 1.0, at: 10_000))
        fixture.addToGeoLocations(oocut.createGeoLocation(latitude: 1.0, longitude: 1.0, accuracy: 1.0, speed: 1.0, at: 10_001))

        fixture.addToAccelerations(oocut.createAcceleration(x: 1.0, y: 1.0, z: 1.0, at: 10_000))
        fixture.addToAccelerations(oocut.createAcceleration(x: 1.0, y: 1.0, z: 1.0, at: 10_001))
        fixture.addToAccelerations(oocut.createAcceleration(x: 1.0, y: 1.0, z: 1.0, at: 10_002))*/

        self.oocut = oocut
        self.fixture = fixture
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        oocut?.deleteMeasurements()
        oocut = nil
        fixture = nil
        super.tearDown()
    }

    /**
     Tests if new measurements are created with the correct identifier and if identifiers are increased for each new measurement. This should even work if one measurement is deleted in between.
    */
    func testCreateMeasurement() {
        guard let secondMeasurement = oocut?.createMeasurement(at: 10_001) else {
            XCTFail()
            return
        }
        guard let firstMeasurement = fixture else {
            XCTFail()
            return
        }

        let testMeasurement = oocut?.loadMeasurement(withIdentifier: fixtureIdentifier!)
        let secondMeasurementIdentifier = secondMeasurement.identifier
        XCTAssertEqual(secondMeasurementIdentifier, firstMeasurement.identifier+1)

        oocut?.delete(measurement: secondMeasurement)

        guard let thirdMeasurement = oocut?.createMeasurement(at: 10_002) else {
            XCTFail()
            return
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

        XCTAssertEqual(measurement.accelerations?.count, 3)
        XCTAssertEqual(measurement.geoLocations?.count, 2)

        oocut.clean(measurement: measurement)

        let loadedMeasurement = oocut.loadMeasurement(withIdentifier: measurement.identifier)

        XCTAssertTrue((measurement.accelerations?.isEmpty)!)
        XCTAssertTrue((loadedMeasurement?.accelerations?.isEmpty)!)
    }

    func testDeleteMeasurement() {
        guard let fixture = fixture else {
            XCTFail("Unable to unwrap test fixture!")
            return
        }

        guard let oocut = oocut else {
            XCTFail("Unable to unwrap object of class under test!")
            return
        }
        XCTAssertEqual(oocut.countMeasurements(), 1)

        oocut.delete(measurement: fixture)

        XCTAssertEqual(oocut.countMeasurements(), 0)
    }
}
