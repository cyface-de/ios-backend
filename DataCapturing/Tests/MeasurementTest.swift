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
 
 - Author: Klemens Muthmann
 - version: 1.0.0
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

    /**
     A happy path test for getting a ``Measurement`` duration.
     */
    func testCalculateDuration() {
        // Arrange
        let measurement = fixture(times: [[1.0, 2.0, 3.0]])

        // Act
        let time = measurement.totalDuration()

        // Assert
        XCTAssertEqual(time, 2)
    }

    /**
     Tests that duration calculation works on ``Measurement`` instances with no location information.
     */
    func testCalculateDurationOnEmpty() {
        // Arrange
        let measurement = fixture(times: [])

        // Act
        let time = measurement.totalDuration()

        // Assert
        XCTAssertEqual(time, 0.0)
    }

    /**
     Tests that duration calculation works on ``Measurement`` instances with only one location.
     */
    func testCalculateDurationOnOneLocation() {
        // Arrange
        let measurement = fixture(times: [[1.0]])

        // Act
        let time = measurement.totalDuration()

        // Assert
        XCTAssertEqual(time, 0.0)
    }

    /// Tests that duration calculation works even if the duration is distributed over multiple tracks and ensures that pauses are not included.
    func testCalculateDurationOnMultipleTracks() {
        // Arrange
        let measurement = fixture(times: [[1.0, 2.0], [3.0, 4.0]])

        // Act
        let time = measurement.totalDuration()

        // Assert
        XCTAssertEqual(time, 2.0)
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

    /// Provide a `Measurement` with random locations at the provided times
    ///
    /// - Parameter times: The timestamps to create the new `Measurement` from, as an array of arrays, where each sub-array matches one track in the new `Measurement`. Each entry is in seconds since 1st of January 1970.
    private func fixture(times: [[Double]]) -> DataCapturing.Measurement {
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
        let tracks = times.map { trackTimes in
            let track = Track(parent: measurement)
            track.locations = trackTimes.map { time in
                return GeoLocation(
                    latitude: Double.random(in: -180.0...180.0),
                    longitude: Double.random(in: -90.0...90.0),
                    accuracy: Double.random(in: 1.0...10.0),
                    speed: 10.0,
                    timestamp: Int64(time*1_000),
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
