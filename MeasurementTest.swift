//
//  MeasurementTest.swift
//  DataCapturing-Unit-Tests
//
//  Created by Klemens Muthmann on 12.01.23.
//

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
