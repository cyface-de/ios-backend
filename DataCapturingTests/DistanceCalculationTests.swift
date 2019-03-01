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
 Tests that distance calculations between geo locations work as expected.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.0.0
 */
class DistanceCalculationTests: XCTestCase {
    func testDefaultCalculation_HappyPath() {
        let oocut = DefaultDistanceCalculationStrategy()
        guard let fromLatitude = CLLocationDegrees(exactly: 51.051953) else {
            XCTFail("Unable to initialize fromLatitude")
            return
        }
        guard let fromLongitude = CLLocationDegrees(exactly: 13.728709) else {
            XCTFail("Unable to initialize fromLongitude")
            return
        }
        let fromLocation = CLLocation(latitude: fromLatitude, longitude: fromLongitude)

        guard let toLatitude = CLLocationDegrees(exactly: 50.117923) else {
            XCTFail("Unable to initialize toLatitude")
            return
        }
        guard let toLongitude = CLLocationDegrees(exactly: 8.636391) else {
            XCTFail("Unable to initialize toLongitude")
            return
        }
        let toLocation = CLLocation(latitude: toLatitude, longitude: toLongitude)

        let expectedDistance = 374120.0

        let calculatedDistance = oocut.calculateDistance(from: fromLocation, to: toLocation)
        let inverseCalculatedDistance = oocut.calculateDistance(from: toLocation, to: fromLocation)

        let expectedAccuracy = expectedDistance * 0.01 // Accuracy should be within 1%
        XCTAssertEqual(expectedDistance, calculatedDistance, accuracy: expectedAccuracy, "Expected distance \(expectedDistance) was not within \(expectedAccuracy) of calculated distance \(calculatedDistance).")
        XCTAssertEqual(calculatedDistance, inverseCalculatedDistance, accuracy: expectedAccuracy, "Calculated distance \(calculatedDistance) was not within \(expectedAccuracy) of inverse calculated distance \(inverseCalculatedDistance).")
    }

    func testDefaultCalculation_ShortDistance() {
        let oocut = DefaultDistanceCalculationStrategy()
        guard let fromLatitude = CLLocationDegrees(exactly: 51.052181) else {
            XCTFail("Unable to initialize fromLatitude")
            return
        }
        guard let fromLongitude = CLLocationDegrees(exactly: 13.728956) else {
            XCTFail("Unable to initialize fromLongitude")
            return
        }
        let fromLocation = CLLocation(latitude: fromLatitude, longitude: fromLongitude)

        guard let toLatitude = CLLocationDegrees(exactly: 51.051837) else {
            XCTFail("Unable to initialize toLatitude")
            return
        }
        guard let toLongitude = CLLocationDegrees(exactly: 13.729010) else {
            XCTFail("Unable to initialize toLongitude")
            return
        }
        let toLocation = CLLocation(latitude: toLatitude, longitude: toLongitude)

        let expectedDistance = 38.44

        let calculatedDistance = oocut.calculateDistance(from: fromLocation, to: toLocation)
        let inverseCalculatedDistance = oocut.calculateDistance(from: toLocation, to: fromLocation)

        let expectedAccuracy = expectedDistance * 0.01 // Accuracy should be within 1%
        XCTAssertEqual(expectedDistance, calculatedDistance, accuracy: expectedAccuracy, "Expected distance \(expectedDistance) was not within \(expectedAccuracy) of calculated distance \(calculatedDistance).")
        XCTAssertEqual(calculatedDistance, inverseCalculatedDistance, accuracy: expectedAccuracy, "Calculated distance \(calculatedDistance) was not within \(expectedAccuracy) of inverse calculated distance \(inverseCalculatedDistance).")
    }
}
