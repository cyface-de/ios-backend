/*
 * Copyright 2018 - 2022 Cyface GmbH
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
 - Version: 1.2.4
 - Since: 1.0.0
 */
class PersistenceTests: XCTestCase {

    /// A `PersistenceLayer` used for testing.
    var oocut: PersistenceLayer!
    /// Some test data.
    var fixture: Int64!
    /// The default mode of transportation used for tests.
    let defaultMode = "BICYCLE"
    static let dataModel = try! CoreDataManager.loadModel()

    /// Initializes the test enviroment by saving some test data to the test `PersistenceLayer`.
    override func setUp() {
        super.setUp()
        let expectation = self.expectation(description: "CoreDataStack initialized successfully!")

        do {
            let manager = CoreDataManager(storeType: NSInMemoryStoreType, migrator: CoreDataMigrator(), modelName: "CyfaceModel", model: PersistenceTests.dataModel)
            let bundle = Bundle(for: type(of: manager))
            try manager.setup(bundle: bundle) { error in


                do {
                    self.oocut = PersistenceLayer(onManager: manager)
                    var measurement = try self.oocut.createMeasurement(at: 10_000, inMode: self.defaultMode)
                    try self.oocut.appendNewTrack(to: &measurement)

                    self.fixture = measurement.identifier

                    try self.oocut.save(locations: [TestFixture.location(latitude: 51.052181, longitude: 13.728956, timestamp: Date(timeIntervalSince1970: 10_000)), TestFixture.location(latitude: 51.051837, longitude: 13.729010, timestamp: Date(timeIntervalSince1970: 10_001))], in: &measurement)
                    try self.oocut.save(accelerations: [TestFixture.randomAcceleration(), TestFixture.randomAcceleration(), TestFixture.randomAcceleration()], in: &measurement)

                    expectation.fulfill()
                } catch let error {
                    XCTFail("Unable to set up due to \(error.localizedDescription)")
                }
            }
        } catch {
            XCTFail("Unable to initialize CoreData due to: \(error)")
        }
            
            waitForExpectations(timeout: 5) { error in
                if let error = error {
                    XCTFail("Unable to setup PersistenceTest \(error)")
                }
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
            let secondMeasurement = try oocut.createMeasurement(at: 10_001, inMode: defaultMode)

            let secondMeasurementIdentifier = secondMeasurement.identifier
            XCTAssertEqual(secondMeasurementIdentifier, fixture+1)
            let events = try oocut.loadEvents(typed: .modalityTypeChange, forMeasurement: secondMeasurement)
            XCTAssertEqual(events.count, 1)

            try oocut.delete(measurement: secondMeasurement.identifier)
            let thirdMeasurement = try oocut.createMeasurement(at: Int64(10_002), inMode: defaultMode)

            XCTAssertEqual(thirdMeasurement.identifier, secondMeasurementIdentifier+1)
        } catch let error {
            XCTFail("Error \(error.localizedDescription)")
        }
    }

    /// Tests if cleaning the test measurement from its additional sensor data is successful.
    func testCleanMeasurement() {
        do {
            let measurement = try oocut.load(measurementIdentifiedBy: fixture)

            let accelerationCount = measurement.accelerationsCount
            let geoLocationCount = try PersistenceLayer.collectGeoLocations(from: measurement).count
            XCTAssertEqual(accelerationCount, 3)
            XCTAssertEqual(geoLocationCount, 2)

            try oocut.clean(measurement: fixture)

            let measurementAfterClean = try oocut.load(measurementIdentifiedBy: fixture)

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
        do {
            var fixtureMeasurement = try oocut.load(measurementIdentifiedBy: fixture)
            try oocut.save(locations: [TestFixture.randomLocation()], in: &fixtureMeasurement)
            try oocut.save(accelerations: [TestFixture.randomAcceleration(), TestFixture.randomAcceleration(), TestFixture.randomAcceleration()], in: &fixtureMeasurement)
            let measurement = try oocut.load(measurementIdentifiedBy: fixture)

            XCTAssertEqual(try PersistenceLayer.collectGeoLocations(from: measurement).count, 3)
            XCTAssertEqual(measurement.accelerationsCount, 6)
        } catch let error {
            XCTFail("Error \(error.localizedDescription)")
        }
    }

    /// Tests that loading the test measurement is successful.
    func testLoadMeasurement() {
        do {
            let measurement = try oocut.load(measurementIdentifiedBy: fixture)

            XCTAssertEqual(measurement.identifier, fixture)
            let events = try oocut.loadEvents(typed: .modalityTypeChange, forMeasurement: measurement)
            XCTAssertEqual(events.count, 1)
            XCTAssertEqual(events[0].value, defaultMode)
            XCTAssertEqual(try PersistenceLayer.collectGeoLocations(from: measurement).count, 2)
            XCTAssertEqual(measurement.accelerationsCount, 3)
        } catch let error {
            XCTFail("Error \(error.localizedDescription)")
        }
    }

    /// Tests that accessing only synchronizable measurements does not return everything.
    func testLoadSynchronizableMeasurements() {
        do {
            var fixtureMeasurement = try oocut.load(measurementIdentifiedBy: fixture)
            fixtureMeasurement.synchronizable = true
            try oocut.save(in: &fixtureMeasurement)
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
            let measurement = try oocut.load(measurementIdentifiedBy: fixture)

            XCTAssertEqual(measurement.trackLength, expectedTrackLength, accuracy: expectedTrackLength * distanceCalculationAccuracy, "Measurement length \(measurement.trackLength) should be within \(distanceCalculationAccuracy*100)% of \(expectedTrackLength).")
        } catch let error {
            XCTFail("Error \(error.localizedDescription)")
        }
    }

    /// Tests that distance is successfully created if new locations are added to a measurement.
    func testDistanceWasAdded() {
        let expectedInitialTrackLength = 38.45660983580925
        let expectedAddedTrackLength = 45.0
        let expectedTrackLength = expectedInitialTrackLength + expectedAddedTrackLength
        let distanceCalculationAccuracy = 0.01

        do {
            var measurement = try oocut.load(measurementIdentifiedBy: fixture)
            XCTAssertEqual(measurement.trackLength, expectedInitialTrackLength)

            let newLocationInput = [TestFixture.location(latitude: 51.051432, longitude: 13.729053, timestamp: Date(timeIntervalSince1970: 10_002))]
            try oocut.save(locations: newLocationInput, in: &measurement)

            XCTAssertEqual(measurement.trackLength, expectedTrackLength, accuracy: expectedTrackLength * distanceCalculationAccuracy, "Measurement length \(measurement.trackLength) should be within \(distanceCalculationAccuracy*100)% of \(expectedTrackLength).")
        } catch let error {
            XCTFail("Error \(error.localizedDescription)")
        }
    }

    /// Tests that geo locations are added successfully to tracks and can be loaded from them.
    func testLoadGeoLocationTracks() throws {
        var measurement = try oocut.load(measurementIdentifiedBy: fixture)

        let tracks = measurement.tracks
        XCTAssertEqual(tracks.count, 1, "There should only be one track in the fixture measurement!")

        let locations = tracks[0].locations
        XCTAssertEqual(locations.count, 2, "There should be two locations in the fixture measurement!")

        try oocut.appendNewTrack(to: &measurement)
        try oocut.save(locations: [TestFixture.location()], in: &measurement)

        let tracksAfterRefresh = measurement.tracks
        XCTAssertEqual(tracksAfterRefresh.count, 2, "There should only be one track in the fixture measurement!")

        let locationsInSecondTrack = tracksAfterRefresh[1].locations
        XCTAssertEqual(locationsInSecondTrack.count, 1, "There should be two locations in the fixture measurement!")
    }

    /// Tests code to load only inactive (all measurements except the one currently captured) measurements in isolation.
    func testLoadInactiveMeasurements() throws {
        let secondMeasurement = try oocut.createMeasurement(at: 20_000, inMode: defaultMode)
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

    /// Tests that loading a cleaned track returns only the valid cleaned locations.
    func testLoadCleanedTrack() throws {
        var measurement = try oocut.createMeasurement(at: DataCapturingService.currentTimeInMillisSince1970(), inMode: defaultMode)

        try oocut.appendNewTrack(to: &measurement)
        try oocut.save(locations: [TestFixture.location(), TestFixture.location(isValid: false), TestFixture.location()], in: &measurement)

        guard var track = measurement.tracks.last else {
            fatalError()
        }
        let cleanTrack = try oocut.loadClean(track: &track)
        XCTAssertEqual(cleanTrack.count, 2)
    }

    /**
     Tests the creation, storage and retrieval of `Event` objects in `CoreData`.
    */
    func testEventCreation_HappyPath() throws {
        var measurement = try oocut.createMeasurement(at: DataCapturingService.currentTimeInMillisSince1970(), inMode: defaultMode)


        let lifecycleStartEvent = try oocut.createEvent(of: .lifecycleStart, parent: &measurement)
        sleep(1)
        let lifecycleStopEvent = try oocut.createEvent(of: .lifecycleStop, parent: &measurement)

        let loadedMeasurement = try oocut.load(measurementIdentifiedBy: measurement.identifier)
        let loadedEvents = loadedMeasurement.events
        XCTAssertEqual(loadedEvents[0].type, EventType.modalityTypeChange)
        XCTAssertEqual(loadedEvents[1].type, lifecycleStartEvent.type)
        XCTAssertEqual(loadedEvents[2].type, lifecycleStopEvent.type)
        XCTAssertLessThanOrEqual(Double(loadedMeasurement.timestamp) / 1_000.0, loadedEvents[1].time.timeIntervalSince1970)
        XCTAssertLessThanOrEqual(loadedEvents[1].time.timeIntervalSince1970, loadedEvents[2].time.timeIntervalSince1970)
    }
}
