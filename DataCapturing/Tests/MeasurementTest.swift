/*
 * Copyright 2023 Cyface GmbH
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
 Tests a ``Measurements`` behaviour.
 */
class MeasurementTest: XCTestCase {

    /**
     A happy path test for calculating the average speed for a ``Measurement``:
     */
    func testCalculateAverageSpeed() {
        // Arrange
        let measurement = fixture(speeds: [[10.0, 5.0], [15.0]])

        // Act
        let averageSpeed = measurement.averageSpeed()

        // Assert
        XCTAssertEqual(averageSpeed, 10.0)
    }

    /**
     Tests that average speed calculation works also for ``Measurement`` instances without any location information.
     */
    func testCalculateAverageSpeedOnEmpty() {
        // Arrange
        let measurement = fixture(speeds: [])

        // Act
        let averageSpeed = measurement.averageSpeed()

        // Assert
        XCTAssertEqual(averageSpeed, 0.0)
    }

    /**
     Tests that average speed calculation works for ``Measurement`` instances with only one location.
     */
    func testCalculateAverageSpeedOnOneLocation() {
        // Arrange
        let measurement = fixture(speeds: [[1.0]])

        // Act
        let averageSpeed = measurement.averageSpeed()

        // Assert
        XCTAssertEqual(averageSpeed, 1.0)
    }

    /// Provide a `Measurement` as a fixture containing locations with the provided speed values.
    private func fixture(speeds: [[Double]]) -> DataCapturing.Measurement {
        let measurement = Measurement(
            identifier: Int64(0),
            synchronizable: true,
            synchronized: false,
            accelerationsCount: 0,
            rotationsCount: 0,
            directionsCount: 0,
            timestamp: Int64(0),
            trackLength: 700,
            events: [],
            tracks: []
        )
        let tracks = speeds.map { trackSpeeds in
            let track = Track(parent: measurement)
            track.locations = trackSpeeds.map { speed in
                return GeoLocation(
                    latitude: Double.random(in: -180.0...180.0),
                    longitude: Double.random(in: -90.0...90.0),
                    accuracy: Double.random(in: 1.0...10.0),
                    speed: speed,
                    timestamp: Int64(Date().timeIntervalSince1970*1_000),
                    isValid: true,
                    parent: track
                )
            }
            return track
        }
        measurement.tracks = tracks

        return measurement
    }
}
