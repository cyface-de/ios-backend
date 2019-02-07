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

    private static let defaultPromiseTimeout = 5.0

    var oocut: PersistenceLayer!
    var fixture: MeasurementEntity!

    override func setUp() {
        super.setUp()

        let promise = expectation(description: "Create fixture measurement!")
        oocut = PersistenceLayer(withDistanceCalculator: DefaultDistanceCalculationStrategy()) { persistence in
            persistence.createMeasurement(at: 10_000, withContext: .bike) { measurement in
                self.fixture = MeasurementEntity(identifier: measurement.identifier, context: MeasurementContext(rawValue: measurement.context!)!)
                persistence.save(locations: [GeoLocation(latitude: 51.052181, longitude: 13.728956, accuracy: 1.0, speed: 1.0, timestamp: 10_000), GeoLocation(latitude: 51.051837, longitude: 13.729010, accuracy: 1.0, speed: 1.0, timestamp: 10_001)], toMeasurement: self.fixture!) {_ in
                    persistence.save(accelerations: [Acceleration(timestamp: 10_000, x: 1.0, y: 1.0, z: 1.0), Acceleration(timestamp: 10_001, x: 1.0, y: 1.0, z: 1.0), Acceleration(timestamp: 10_002, x: 1.0, y: 1.0, z: 1.0)], toMeasurement: self.fixture!) {
                        promise.fulfill()
                    }
                }
            }
        }

        wait(for: [promise], timeout: PersistenceTests.defaultPromiseTimeout)
    }

    override func tearDown() {
        let promise = expectation(description: "Clean database")
        oocut.delete {
            promise.fulfill()
        }
        oocut = nil
        fixture = nil
        wait(for: [promise], timeout: PersistenceTests.defaultPromiseTimeout)
        super.tearDown()
    }

    /**
     Tests if new measurements are created with the correct identifier and if identifiers are increased for each new measurement. This should even work if one measurement is deleted in between.
     */
    func testCreateMeasurement() {
        let testPromise = expectation(description: "Create measurements")
        oocut.createMeasurement(at: 10_001, withContext: .bike) { secondMeasurement in
            guard let firstMeasurement = self.fixture else {
                fatalError()
            }

            let secondMeasurementIdentifier = secondMeasurement.identifier
            XCTAssertEqual(secondMeasurementIdentifier, firstMeasurement.identifier+1)

            self.oocut!.delete(measurement: MeasurementEntity(identifier: secondMeasurement.identifier, context: MeasurementContext(rawValue: secondMeasurement.context!)!)) {
                self.oocut!.createMeasurement(at: 10_002, withContext: .bike) { thirdMeasurement in
                    XCTAssertEqual(thirdMeasurement.identifier, secondMeasurementIdentifier+1)
                    testPromise.fulfill()
                }
            }
        }

        wait(for: [testPromise], timeout: PersistenceTests.defaultPromiseTimeout)
    }

    func testCleanMeasurement() {
        let testPromise = expectation(description: "Clean successful")

        oocut.load(measurementIdentifiedBy: fixture.identifier) { (measurementMo) in
            let accelerationCount = measurementMo.accelerationsCount
            let geoLocationCount = measurementMo.geoLocations!.count
            XCTAssertEqual(accelerationCount, 3)
            XCTAssertEqual(geoLocationCount, 2)

            self.oocut.clean(measurement: self.fixture) {
                self.oocut.load(measurementIdentifiedBy: self.fixture.identifier) { measurementMo in
                    XCTAssertEqual(measurementMo.accelerationsCount, 0, "Accelerations have not been empty after cleaning!")
                    XCTAssertFalse(measurementMo.geoLocations!.count==0, "Geo Locations was empty after cleaning!")
                    testPromise.fulfill()
                }
            }
        }

        wait(for: [testPromise], timeout: PersistenceTests.defaultPromiseTimeout)
    }

    func testDeleteMeasurement() {
        let testPromise = expectation(description: "Succesful measurement deletion")

        oocut!.countMeasurements { count in
            XCTAssertEqual(count, 1, "There should be one measurement before deleting it! There have been \(count).")

            self.oocut!.delete(measurement: self.fixture) {
                self.oocut!.countMeasurements { count in
                    XCTAssertEqual(count, 0, "There should be no measurement after deleting it! There where \(count).")
                    testPromise.fulfill()
                }
            }
        }

        wait(for: [testPromise], timeout: PersistenceTests.defaultPromiseTimeout)
    }

    func testMergeDataToExistingMeasurement() {
        let additionalLocation = GeoLocation(latitude: 1.0, longitude: 1.0, accuracy: 800, speed: 5.0, timestamp: 10_005)
        let additionalAccelerations = [
            Acceleration(timestamp: 10_005, x: 1.0, y: 1.0, z: 1.0),
            Acceleration(timestamp: 10_006, x: 1.0, y: 1.0, z: 1.0),
            Acceleration(timestamp: 10_007, x: 1.0, y: 1.0, z: 1.0)
        ]
        let testPromise = expectation(description: "Merge data on the same measurement!")

        oocut.save(locations: [additionalLocation], toMeasurement: fixture) { _ in
            self.oocut!.save(accelerations: additionalAccelerations, toMeasurement: self.fixture!) {
                self.oocut!.load(measurementIdentifiedBy: self.fixture!.identifier) { (measurement) in
                    XCTAssertEqual(measurement.geoLocations!.count, 3)
                    XCTAssertEqual(measurement.accelerationsCount, 6)
                    testPromise.fulfill()
                }
            }
        }

        wait(for: [testPromise], timeout: PersistenceTests.defaultPromiseTimeout)
    }

    func testLoadMeasurement() {
        let promise = expectation(description: "Error while loading measurements!")
        oocut!.load(measurementIdentifiedBy: fixture!.identifier) { (measurement) in
            XCTAssert(measurement.identifier == self.fixture!.identifier)
            XCTAssert(measurement.context == "BICYCLE")
            XCTAssert(measurement.geoLocations!.count == 2)
            XCTAssert(measurement.accelerationsCount == 3)
            promise.fulfill()
        }

        wait(for: [promise], timeout: PersistenceTests.defaultPromiseTimeout)

    }

    func testLoadSynchronizableMeasurements() {
        let promisePriorClean = expectation(description: "Error while loading measurements!")
        var countOfLoadedMeasurementsPriorClean = 0
        oocut.loadSynchronizableMeasurements { (measurements) in
            countOfLoadedMeasurementsPriorClean += measurements.count
            promisePriorClean.fulfill()
        }

        wait(for: [promisePriorClean], timeout: PersistenceTests.defaultPromiseTimeout)

        let promiseClean = expectation(description: "Error while cleaning fixture measurement!")
        oocut.clean(measurement: fixture) {
            promiseClean.fulfill()
        }

        wait(for: [promiseClean], timeout: PersistenceTests.defaultPromiseTimeout)

        let promisePostClean = expectation(description: "Error while loading measurements!")
        var countOfLoadedMeasurementsPostClean = 0
        oocut.loadSynchronizableMeasurements { (measurements) in
            countOfLoadedMeasurementsPostClean += measurements.count
            promisePostClean.fulfill()
        }

        wait(for: [promisePostClean], timeout: PersistenceTests.defaultPromiseTimeout)
        XCTAssertEqual(countOfLoadedMeasurementsPriorClean, 1)
        XCTAssertEqual(countOfLoadedMeasurementsPostClean, 0)
    }

    func testDistanceWasCalculated() {
        let expectedTrackLength = 38.44
        let distanceCalculationAccuracy = 0.01

        let testPromise = expectation(description: "Measurement was loaded.")
        oocut.load(measurementIdentifiedBy: fixture.identifier) { measurement in
            XCTAssertEqual(measurement.trackLength, expectedTrackLength, accuracy: expectedTrackLength * distanceCalculationAccuracy, "Measurement length \(measurement.trackLength) should be within \(distanceCalculationAccuracy*100)% of \(expectedTrackLength).")
            testPromise.fulfill()
        }

        wait(for: [testPromise], timeout: PersistenceTests.defaultPromiseTimeout)
    }

    func testDistanceWasAdded() {
        let expectedTrackLength = 83.57
        let distanceCalculationAccuracy = 0.01

        let testPromise = expectation(description: "Measurement was saved.")
        let locations: [GeoLocation] = [GeoLocation(latitude: 51.051432, longitude: 13.729053, accuracy: 1.0, speed: 1.0, timestamp: 10_300)]
        oocut.save(locations: locations, toMeasurement: fixture, onFinished: { measurement in
            XCTAssertEqual(measurement.trackLength, expectedTrackLength, accuracy: expectedTrackLength * distanceCalculationAccuracy, "Measurement length \(measurement.trackLength) should be within \(distanceCalculationAccuracy*100)% of \(expectedTrackLength).")
            testPromise.fulfill()
        })

        wait(for: [testPromise], timeout: PersistenceTests.defaultPromiseTimeout)
    }
}
