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
import CoreData
@testable import DataCapturing

/**
 Tests that using the `PersistenceLayer` works as expected.

 - Author: Klemens Muthmann
 - Version: 1.1.2
 - Since: 1.0.0
 */
class PersistenceTests: XCTestCase {

    /// A `PersistenceLayer` used for testing.
    var oocut: PersistenceLayer!
    /// Some test data.
    var fixture: MeasurementEntity!

    /// Initializes the test enviroment by saving some test data to the test `PersistenceLayer`.
    override func setUp() {
        super.setUp()
        do {
            let manager = CoreDataManager(storeType: NSInMemoryStoreType, migrator: CoreDataMigrator())
            guard let bundle = Bundle(identifier: "de.cyface.DataCapturing") else {
                fatalError()
            }
            manager.setup(bundle: bundle)
            oocut = PersistenceLayer(onManager: manager)
            oocut.context = oocut.makeContext()
            let measurement = try oocut.createMeasurement(at: 10_000, withContext: .bike)
            oocut.appendNewTrack(to: measurement)

            fixture = MeasurementEntity(identifier: measurement.identifier, context: MeasurementContext(rawValue: measurement.context!)!)

            try oocut.save(locations: [GeoLocation(latitude: 51.052181, longitude: 13.728956, accuracy: 1.0, speed: 1.0, timestamp: 10_000), GeoLocation(latitude: 51.051837, longitude: 13.729010, accuracy: 1.0, speed: 1.0, timestamp: 10_001)], in: measurement)
            try oocut.save(accelerations: [Acceleration(timestamp: 10_000, x: 1.0, y: 1.0, z: 1.0), Acceleration(timestamp: 10_001, x: 1.0, y: 1.0, z: 1.0), Acceleration(timestamp: 10_002, x: 1.0, y: 1.0, z: 1.0)], in: measurement)

        } catch let error {
            XCTFail("Unable to set up due to \(error.localizedDescription)")
        }
    }

    /// Cleans the test enviroment by deleting all data.
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

    /// Tests if cleaning the test measurement from its additional sensor data is successful.
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

    /// Tests that deleting a measurement is successful.
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

    /// Tests that writing some data to an existing measurement is successful.
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

    /// Tests that loading the test measurement is successful.
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

    /// Tests that accessing only synchronizable measurements does not return everything.
    func testLoadSynchronizableMeasurements() {
        do {
            let fixtureMeasurement = try oocut.load(measurementIdentifiedBy: fixture.identifier)
            fixtureMeasurement.synchronizable = true
            oocut.context?.saveRecursively()
            let countOfLoadedMeasurementsPriorClean = try oocut.loadSynchronizableMeasurements().count

            try oocut.clean(measurement: fixture)

            let countOfLoadedMeasurementsPostClean = try oocut.loadSynchronizableMeasurements().count

            XCTAssertEqual(countOfLoadedMeasurementsPriorClean, 1)
            XCTAssertEqual(countOfLoadedMeasurementsPostClean, 0)
        } catch let error {
            XCTFail("Error \(error.localizedDescription)")
        }
    }

    /// Tests that some distance is calculated for the test measurement.
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

    /// Tests that distance is successfully created if new locations are added to a measurement.
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

    /// Tests that geo locations are added successfully to tracks and can be loaded from them.
    func testLoadGeoLocationTracks() throws {
        let measurement = try oocut.load(measurementIdentifiedBy: fixture.identifier)

        guard let tracks = measurement.tracks?.array as? [Track] else {
            return XCTFail("Unable to load tracks!")
        }
        XCTAssertEqual(tracks.count, 1, "There should only be one track in the fixture measurement!")

        guard let locations = tracks[0].locations?.array as? [GeoLocationMO] else {
            return XCTFail("Unable to load geo locations!")
        }
        XCTAssertEqual(locations.count, 2, "There should be two locations in the fixture measurement!")

        oocut.appendNewTrack(to: measurement)
        try oocut.save(locations: [GeoLocation(latitude: 2.0, longitude: 2.0, accuracy: 1.0, speed: 10.0, timestamp: 5)], in: measurement)

        guard let tracksAfterRefresh = measurement.tracks?.array as? [Track] else {
            return XCTFail("Unable to load tracks!")
        }
        XCTAssertEqual(tracksAfterRefresh.count, 2, "There should only be one track in the fixture measurement!")

        guard let locationsInSecondTrack = tracksAfterRefresh[1].locations?.array as? [GeoLocationMO] else {
            return XCTFail("Unable to load geo locations!")
        }
        XCTAssertEqual(locationsInSecondTrack.count, 1, "There should be two locations in the fixture measurement!")
    }

    /// Tests code to load only inactive (all measurements except the one currently captured) measurements in isolation.
    func testLoadInactiveMeasurements() throws {
        let secondMeasurement = try oocut.createMeasurement(at: 20_000, withContext: .bike)
        let secondMeasurementIdentifier = secondMeasurement.identifier
        let measurements = try oocut.loadMeasurements()

        // Filter active measurement if any.
        let filteredMeasurements = measurements.filter { measurement in
            return measurement.identifier != secondMeasurementIdentifier
        }

        XCTAssertEqual(filteredMeasurements.count, 1)
        XCTAssertEqual(filteredMeasurements.first!.identifier, 1)
        XCTAssertTrue(filteredMeasurements.first!.trackLength > 0.0)
    }
}
