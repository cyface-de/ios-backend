/*
 * Copyright 2018 Cyface GmbH
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

class PersistenceTests: XCTestCase {

    var oocut: PersistenceLayer!
    var fixture: MeasurementEntity!

    override func setUp() {
        super.setUp()
        do {
            oocut = try PersistenceLayer(withDistanceCalculator: DefaultDistanceCalculationStrategy())
            oocut.context = oocut.makeContext()
            let measurement = try oocut.createMeasurement(at: 10_000, withContext: .bike)
            try oocut.appendNewTrack(to: measurement)

            fixture = MeasurementEntity(identifier: measurement.identifier, context: MeasurementContext(rawValue: measurement.context!)!)

            try oocut.save(locations: [GeoLocation(latitude: 51.052181, longitude: 13.728956, accuracy: 1.0, speed: 1.0, timestamp: 10_000), GeoLocation(latitude: 51.051837, longitude: 13.729010, accuracy: 1.0, speed: 1.0, timestamp: 10_001)], in: measurement)
            try oocut.save(accelerations: [Acceleration(timestamp: 10_000, x: 1.0, y: 1.0, z: 1.0), Acceleration(timestamp: 10_001, x: 1.0, y: 1.0, z: 1.0), Acceleration(timestamp: 10_002, x: 1.0, y: 1.0, z: 1.0)], in: measurement)

        } catch let error {
            XCTFail("Unable to set up due to \(error.localizedDescription)")
        }
    }

    override func tearDown() {
        do {
            try oocut.delete()
        } catch {
            fatalError()
        }
        oocut = nil
        fixture = nil
        super.tearDown()
    }

    /**
     Tests if new measurements are created with the correct identifier and if identifiers are increased for each new measurement. This should even work if one measurement is deleted in between.
     */
    func testCreateMeasurement() {
        do {
            let secondMeasurement = try oocut.createMeasurement(at: 10_001, withContext: .bike)

            let secondMeasurementIdentifier = secondMeasurement.identifier
            XCTAssertEqual(secondMeasurementIdentifier, fixture.identifier+1)

            try oocut.delete(measurement: MeasurementEntity(identifier: secondMeasurement.identifier, context: MeasurementContext(rawValue: secondMeasurement.context!)!))
            let thirdMeasurement = try oocut.createMeasurement(at: Int64(10_002), withContext: MeasurementContext.bike)

            XCTAssertEqual(thirdMeasurement.identifier, secondMeasurementIdentifier+1)
        } catch let error {
            XCTFail("Error \(error.localizedDescription)")
        }
    }

    func testCleanMeasurement() {
        do {
            let measurement = try oocut.load(measurementIdentifiedBy: fixture.identifier)

            let accelerationCount = measurement.accelerationsCount
            let geoLocationCount = try PersistenceLayer.collectGeoLocations(from: measurement).count
            XCTAssertEqual(accelerationCount, 3)
            XCTAssertEqual(geoLocationCount, 2)

            try oocut.clean(measurement: fixture)

            let measurementAfterClean = try oocut.load(measurementIdentifiedBy: fixture.identifier)

            XCTAssertEqual(measurementAfterClean.accelerationsCount, 0, "Accelerations have not been empty after cleaning!")
            let geoLocationCountAfterClean = try PersistenceLayer.collectGeoLocations(from: measurementAfterClean).count
            XCTAssertFalse(geoLocationCountAfterClean==0, "Geo Locations was empty after cleaning!")
        } catch let error {
            XCTFail("Error \(error.localizedDescription)")
        }
    }

    func testDeleteMeasurement() {
        do {
            let count = try oocut.countMeasurements()

            XCTAssertEqual(count, 1, "There should be one measurement before deleting it! There have been \(count).")

            try oocut.delete(measurement: fixture)

            let countAfterDelete = try oocut.countMeasurements()

            XCTAssertEqual(countAfterDelete, 0, "There should be no measurement after deleting it! There where \(count).")
        } catch let error {
            XCTFail("Error \(error.localizedDescription)")
        }
    }

    func testMergeDataToExistingMeasurement() {
        let additionalLocation = GeoLocation(latitude: 1.0, longitude: 1.0, accuracy: 800, speed: 5.0, timestamp: 10_005)
        let additionalAccelerations = [
            Acceleration(timestamp: 10_005, x: 1.0, y: 1.0, z: 1.0),
            Acceleration(timestamp: 10_006, x: 1.0, y: 1.0, z: 1.0),
            Acceleration(timestamp: 10_007, x: 1.0, y: 1.0, z: 1.0)
        ]

        do {
            let fixtureMeasurement = try oocut.load(measurementIdentifiedBy: fixture.identifier)
            try oocut.save(locations: [additionalLocation], in: fixtureMeasurement)
            try oocut.save(accelerations: additionalAccelerations, in: fixtureMeasurement)
            let measurement = try oocut.load(measurementIdentifiedBy: fixture.identifier)

            XCTAssertEqual(try PersistenceLayer.collectGeoLocations(from: measurement).count, 3)
            XCTAssertEqual(measurement.accelerationsCount, 6)
        } catch let error {
            XCTFail("Error \(error.localizedDescription)")
        }
    }

    func testLoadMeasurement() {
        do {
            let measurement = try oocut.load(measurementIdentifiedBy: fixture.identifier)

            XCTAssert(measurement.identifier == fixture.identifier)
            XCTAssert(measurement.context == "BICYCLE")
            XCTAssert(try PersistenceLayer.collectGeoLocations(from: measurement).count == 2)
            XCTAssert(measurement.accelerationsCount == 3)
        } catch let error {
            XCTFail("Error \(error.localizedDescription)")
        }
    }

    func testLoadSynchronizableMeasurements() {
        do {
            let countOfLoadedMeasurementsPriorClean = try oocut.loadSynchronizableMeasurements().count

            try oocut.clean(measurement: fixture)

            let countOfLoadedMeasurementsPostClean = try oocut.loadSynchronizableMeasurements().count

            XCTAssertEqual(countOfLoadedMeasurementsPriorClean, 1)
            XCTAssertEqual(countOfLoadedMeasurementsPostClean, 0)
        } catch let error {
            XCTFail("Error \(error.localizedDescription)")
        }
    }

    func testDistanceWasCalculated() {
        let expectedTrackLength = 38.44
        let distanceCalculationAccuracy = 0.01

        do {
            let measurement = try oocut.load(measurementIdentifiedBy: fixture.identifier)

            XCTAssertEqual(measurement.trackLength, expectedTrackLength, accuracy: expectedTrackLength * distanceCalculationAccuracy, "Measurement length \(measurement.trackLength) should be within \(distanceCalculationAccuracy*100)% of \(expectedTrackLength).")
        } catch let error {
            XCTFail("Error \(error.localizedDescription)")
        }
    }

    func testDistanceWasAdded() {
        let expectedTrackLength = 83.57
        let distanceCalculationAccuracy = 0.01

        let locations: [GeoLocation] = [GeoLocation(latitude: 51.051432, longitude: 13.729053, accuracy: 1.0, speed: 1.0, timestamp: 10_300)]

        do {
            let measurement = try oocut.load(measurementIdentifiedBy: fixture.identifier)
            try oocut.save(locations: locations, in: measurement)

            XCTAssertEqual(measurement.trackLength, expectedTrackLength, accuracy: expectedTrackLength * distanceCalculationAccuracy, "Measurement length \(measurement.trackLength) should be within \(distanceCalculationAccuracy*100)% of \(expectedTrackLength).")
        } catch let error {
            XCTFail("Error \(error.localizedDescription)")
        }
    }
}
