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
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPersistenceLayer() {
        let oocut = PersistenceLayer()
        let measurement = oocut.createMeasurement(at: 10_000)
        measurement.synchronized = false
        measurement.addToGeoLocations(oocut.createGeoLocation(latitude: 1.0, longitude: 1.0, accuracy: 1.0, speed: 1.0, at: 10_000))
        measurement.addToGeoLocations(oocut.createGeoLocation(latitude: 1.0, longitude: 1.0, accuracy: 1.0, speed: 1.0, at: 10_001))

        measurement.addToAccelerations(oocut.createAcceleration(x: 1.0, y: 1.0, z: 1.0, at: 10_000))
        measurement.addToAccelerations(oocut.createAcceleration(x: 1.0, y: 1.0, z: 1.0, at: 10_001))
        measurement.addToAccelerations(oocut.createAcceleration(x: 1.0, y: 1.0, z: 1.0, at: 10_002))

        XCTAssertEqual(measurement.accelerations?.count, 3)
        XCTAssertEqual(measurement.geoLocations?.count, 2)

        oocut.clean(measurement: measurement)

        let loadedMeasurement = oocut.loadMeasurement(withIdentifier: measurement.identifier)

        XCTAssertTrue((measurement.accelerations?.isEmpty)!)
        XCTAssertTrue((loadedMeasurement?.accelerations?.isEmpty)!)

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
}
