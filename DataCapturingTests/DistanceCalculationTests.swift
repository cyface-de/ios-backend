//
//  DistanceCalculationTests.swift
//  DataCapturingTests
//
//  Created by Team Cyface on 07.02.19.
//  Copyright © 2019 Cyface GmbH. All rights reserved.
//

import XCTest
import CoreLocation
@testable import DataCapturing

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

        let expectedAccuracy = expectedDistance * 0.1 // Accuracy should be within 1%
        XCTAssertEqual(expectedDistance, calculatedDistance, accuracy: expectedAccuracy, "Expected distance \(expectedDistance) was not within \(expectedAccuracy) of calculated distance \(calculatedDistance).")
        XCTAssertEqual(calculatedDistance, inverseCalculatedDistance, accuracy: expectedAccuracy, "Calculated distance \(calculatedDistance) was not within \(expectedAccuracy) of inverse calculated distance \(inverseCalculatedDistance).")
    }
}
