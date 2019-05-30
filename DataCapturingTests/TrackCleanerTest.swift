//
//  TrackCleanerTest.swift
//  DataCapturingTests
//
//  Created by Team Cyface on 30.05.19.
//  Copyright © 2019 Cyface GmbH. All rights reserved.
//

import XCTest
import CoreLocation
@testable import DataCapturing

class TrackCleanerTest: XCTestCase {

    var oocut: TrackCleaner!

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        oocut = DefaultTrackCleaner()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testValidLocation() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertTrue(oocut.isValid(location: TrackCleanerTest.location(speed: 5.0)))
    }

    func testInvalidLocation() {
        XCTAssertFalse(oocut.isValid(location: TrackCleanerTest.location(verticalAccuracy: 30.0)))
        XCTAssertFalse(oocut.isValid(location: TrackCleanerTest.location(speed: 0.5)))
        XCTAssertFalse(oocut.isValid(location: TrackCleanerTest.location(speed: 5_000.2)))
        XCTAssertFalse(oocut.isValid(location: TrackCleanerTest.location(verticalAccuracy: 20.1, speed: 0.9)))
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            _ = oocut.isValid(location: TrackCleanerTest.location())
        }
    }

    static func location(coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 1.0, longitude: 1.0), altitude: CLLocationDistance = 1.0, horizontalAccuracy: CLLocationAccuracy = 1.0, verticalAccuracy: CLLocationAccuracy = 1.0, course: CLLocationDirection = 1.0, speed: CLLocationSpeed = 1.0, timestamp: Date = Date()) -> CLLocation {
        return CLLocation(coordinate: coordinate, altitude: altitude, horizontalAccuracy: horizontalAccuracy, verticalAccuracy: verticalAccuracy, course: course, speed: speed, timestamp: timestamp)
    }

}
