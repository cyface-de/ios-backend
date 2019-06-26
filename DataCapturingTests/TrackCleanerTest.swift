/*
 * Copyright 2019 Cyface GmbH
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
import CoreLocation
@testable import DataCapturing

/**
 Tests the correct workings of the `TrackCleaner` used for removing pauses from captured tracks.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 1.0.0
 */
class TrackCleanerTest: XCTestCase {

    /// An instance of the class under test
    var oocut: TrackCleaner!

    /// Initializes the test instance
    override func setUp() {
        super.setUp()
        oocut = DefaultTrackCleaner()
    }

    /// Deletes the test instance
    override func tearDown() {
        oocut = nil
        super.tearDown()
    }

    /// Tests that the `TrackCleaner` works correctly on a valid location.
    func testValidLocation() {
        XCTAssertTrue(oocut.isValid(location: TrackCleanerTest.location(speed: 5.0)))
    }

    /// Tests that the `TrackCleaner` reports false on invalid locations.
    func testInvalidLocation() {
        XCTAssertFalse(oocut.isValid(location: TrackCleanerTest.location(verticalAccuracy: 30.0)))
        XCTAssertFalse(oocut.isValid(location: TrackCleanerTest.location(speed: 0.5)))
        XCTAssertFalse(oocut.isValid(location: TrackCleanerTest.location(speed: 5_000.2)))
        XCTAssertFalse(oocut.isValid(location: TrackCleanerTest.location(verticalAccuracy: 20.1, speed: 0.9)))
    }

    /// Tests that `TrackCleaner` is fast enough to be called for each new geo location
    func testPerformance() {
        self.measure {
            _ = oocut.isValid(location: TrackCleanerTest.location())
        }
    }

    /**
     Returns a fixture location for testing against. Default values are provided for all required parameters, so it is possible to only select the parameters required during the current test.

     - Parameters:
        - coordinate: A coordinate structure containing the latitude and longitude values.
        - altitude: The altitude value for the location.
        - horizontalAccuracy: The radius of uncertainty for the geographical coordinate, measured in meters. Specify a negative number to indicate that the geographical coordinate is invalid.
        - vAccuracy: The accuracy of the altitude value, measured in meters. Specify a negative number to indicate that the altitude is invalid.
        - course: The direction of travel for the location, measured in degrees relative to due north and continuing clockwise around the compass.
        - speed: The current speed associated with this location, measured in meters per second.
        - timestamp: The time to associate with the location object. Typically, you specify the current time.
     - Returns: A location object initialized with the specified geographical coordinate, altitude, and course information.
 */
    static func location(coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 1.0, longitude: 1.0), altitude: CLLocationDistance = 1.0, horizontalAccuracy: CLLocationAccuracy = 1.0, verticalAccuracy: CLLocationAccuracy = 1.0, course: CLLocationDirection = 1.0, speed: CLLocationSpeed = 1.0, timestamp: Date = Date()) -> CLLocation {
        return CLLocation(coordinate: coordinate, altitude: altitude, horizontalAccuracy: horizontalAccuracy, verticalAccuracy: verticalAccuracy, course: course, speed: speed, timestamp: timestamp)
    }

}
