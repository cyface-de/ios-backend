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
 - Version: 1.3.0
 - Since: 1.0.0
 */
class PersistenceTests: XCTestCase {

    /// A `PersistenceLayer` used for testing.
    var oocut: PersistenceLayer!
    /// Some test data.
    var fixture: DataCapturing.Measurement?
    /// The default mode of transportation used for tests.
    let defaultMode = "BICYCLE"
    /// Load the data model for the test data stack.
    static let dataModel = try! CoreDataManager.load()

    /// Initializes the test enviroment by saving some test data to the test `PersistenceLayer`.
    override func setUpWithError() throws {
        super.setUp()
        let expectation = self.expectation(description: "CoreDataStack initialized successfully!")

        let manager = CoreDataManager(storeType: NSInMemoryStoreType, migrator: CoreDataMigrator(), modelName: "CyfaceModel", model: PersistenceTests.dataModel)
        let bundle = Bundle(for: type(of: manager))
        try manager.setup(bundle: bundle) { error in
            defer {
                expectation.fulfill()
            }

            do {
                self.oocut = PersistenceLayer(onManager: manager)
                var measurement = try self.oocut.createMeasurement(at: 10_000, inMode: self.defaultMode)

                try self.oocut.appendNewTrack(to: &measurement)

                try self.oocut.save(locations: [TestFixture.location(latitude: 51.052181, longitude: 13.728956, timestamp: Date(timeIntervalSince1970: 10_000)), TestFixture.location(latitude: 51.051837, longitude: 13.729010, timestamp: Date(timeIntervalSince1970: 10_001))], in: &measurement)
                let accelerations = [TestFixture.randomAcceleration(), TestFixture.randomAcceleration(), TestFixture.randomAcceleration()]
                try self.oocut.save(accelerations: accelerations, in: &measurement)
                self.fixture = try self.oocut.load(measurementIdentifiedBy: measurement.identifier)
                guard self.fixture != nil else {
                    return XCTFail("Unable to set up. Fixture was not initialised!")
                }
            } catch let error {
                XCTFail("Unable to set up due to:\n \(error.localizedDescription)")
            }
        }

        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail("Unable to setup PersistenceTest \(error)")
            }
        }
    }

    /// Cleans the test enviroment by deleting all data.
    override func tearDownWithError() throws {
        try oocut.delete()
        oocut = nil
        fixture = nil
        try super.tearDownWithError()
    }

    /**
     Tests if new measurements are created with the correct identifier and if identifiers are increased for each new measurement. This should even work if one measurement is deleted in between.
     */
    func testCreateMeasurement() throws {
        let fixture = try XCTUnwrap(fixture)
        let secondMeasurement = try oocut.createMeasurement(at: 10_001, inMode: defaultMode)

        let secondMeasurementIdentifier = secondMeasurement.identifier
        XCTAssertEqual(secondMeasurementIdentifier, fixture.identifier+1)
        let events = try oocut.loadEvents(typed: .modalityTypeChange, forMeasurement: secondMeasurement)
        XCTAssertEqual(events.count, 1)

        try oocut.delete(measurement: secondMeasurement.identifier)
        let thirdMeasurement = try oocut.createMeasurement(at: UInt64(10_002), inMode: defaultMode)

        XCTAssertEqual(thirdMeasurement.identifier, secondMeasurementIdentifier+1)
    }

    /// Tests if cleaning the test measurement from its additional sensor data is successful.
    func testCleanMeasurement() throws {
        let fixture = try XCTUnwrap(fixture)
        let sensorValueFile = SensorValueFile(fileType: .accelerationValueType)
        let accelerationCount = try sensorValueFile.load(from: fixture).count
        let geoLocationCount = PersistenceLayer.collectGeoLocations(from: fixture).count
        XCTAssertEqual(accelerationCount, 3)
        XCTAssertEqual(geoLocationCount, 2)

        try oocut.clean(measurement: fixture.identifier)

        let measurementAfterClean = try oocut.load(measurementIdentifiedBy: fixture.identifier)
        let accelerationsAfterClean = try sensorValueFile.load(from: measurementAfterClean)

        XCTAssertEqual(accelerationsAfterClean.count, 0, "Accelerations have not been empty after cleaning!")
        let geoLocationCountAfterClean = PersistenceLayer.collectGeoLocations(from: measurementAfterClean).count
        XCTAssertFalse(geoLocationCountAfterClean==0, "Geo Locations was empty after cleaning!")
    }

    /// Tests that deleting a measurement is successful.
    func testDeleteMeasurement() throws {
        let fixture = try XCTUnwrap(fixture)
        let count = try oocut.countMeasurements()

        XCTAssertEqual(count, 1, "There should be one measurement before deleting it! There have been \(count).")

        try oocut.delete(measurement: fixture.identifier)

        let countAfterDelete = try oocut.countMeasurements()

        XCTAssertEqual(countAfterDelete, 0, "There should be no measurement after deleting it! There where \(count).")
    }

    /// Tests that writing some data to an existing measurement is successful.
    func testMergeDataToExistingMeasurement() throws {
        var fixture = try XCTUnwrap(fixture)
        try oocut.save(locations: [TestFixture.randomLocation()], in: &fixture)
        try oocut.save(accelerations: [TestFixture.randomAcceleration(), TestFixture.randomAcceleration(), TestFixture.randomAcceleration()], in: &fixture)
        let measurement = try oocut.load(measurementIdentifiedBy: fixture.identifier)

        let mergedSensorValues = try SensorValueFile(fileType: .accelerationValueType).load(from: measurement)
        XCTAssertEqual(PersistenceLayer.collectGeoLocations(from: measurement).count, 3)
        XCTAssertEqual(mergedSensorValues.count, 6)
    }

    /// Tests that loading the test measurement is successful.
    func testLoadMeasurement() throws {
        let fixture = try XCTUnwrap(fixture)
        let measurement = try oocut.load(measurementIdentifiedBy: fixture.identifier)

        XCTAssertEqual(measurement, fixture)
        let events = try oocut.loadEvents(typed: .modalityTypeChange, forMeasurement: measurement)
        let accelerations = try SensorValueFile(fileType: .accelerationValueType).load(from: measurement)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].value, defaultMode)
        XCTAssertEqual(PersistenceLayer.collectGeoLocations(from: measurement).count, 2)
        XCTAssertEqual(accelerations.count, 3)
    }

    /// Tests that accessing only synchronizable measurements does not return everything.
    func testLoadSynchronizableMeasurements() throws {
        let fixture = try XCTUnwrap(fixture)
        fixture.synchronizable = true
        _ = try oocut.save(measurement: fixture)
        let countOfLoadedMeasurementsPriorClean = try oocut.loadSynchronizableMeasurements().count

        try oocut.clean(measurement: fixture.identifier)

        let countOfLoadedMeasurementsPostClean = try oocut.loadSynchronizableMeasurements().count

        XCTAssertEqual(countOfLoadedMeasurementsPriorClean, 1)
        XCTAssertEqual(countOfLoadedMeasurementsPostClean, 0)
    }

    /// Tests that some distance is calculated for the test measurement.
    func testDistanceWasCalculated() throws {
        let fixture = try XCTUnwrap(fixture)
        let expectedTrackLength = 38.44
        let distanceCalculationAccuracy = 0.01

        XCTAssertEqual(fixture.trackLength, expectedTrackLength, accuracy: expectedTrackLength * distanceCalculationAccuracy, "Measurement length \(fixture.trackLength) should be within \(distanceCalculationAccuracy*100)% of \(expectedTrackLength).")
    }

    /// Tests that distance is successfully created if new locations are added to a measurement.
    func testDistanceWasAdded() throws {
        let expectedInitialTrackLength = 38.45660983580925
        let expectedAddedTrackLength = 45.0
        let expectedTrackLength = expectedInitialTrackLength + expectedAddedTrackLength
        let distanceCalculationAccuracy = 0.01
        var fixture = try XCTUnwrap(fixture)

        XCTAssertEqual(fixture.trackLength, expectedInitialTrackLength)

        let newLocationInput = [TestFixture.location(latitude: 51.051432, longitude: 13.729053, timestamp: Date(timeIntervalSince1970: 10_002))]
        try oocut.save(locations: newLocationInput, in: &fixture)

        XCTAssertEqual(fixture.trackLength, expectedTrackLength, accuracy: expectedTrackLength * distanceCalculationAccuracy, "Measurement length \(fixture.trackLength) should be within \(distanceCalculationAccuracy*100)% of \(expectedTrackLength).")
    }

    /// Tests that geo locations are added successfully to tracks and can be loaded from them.
    func testLoadGeoLocationTracks() throws {
        var fixture = try XCTUnwrap(fixture)
        let tracks = fixture.tracks
        XCTAssertEqual(tracks.count, 1, "There should only be one track in the fixture measurement!")

        let locations = tracks[0].locations
        XCTAssertEqual(locations.count, 2, "There should be two locations in the fixture measurement!")

        try oocut.appendNewTrack(to: &fixture)
        try oocut.save(locations: [TestFixture.location()], in: &fixture)

        let tracksAfterRefresh = fixture.tracks
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
        // Arrange
        var measurement = try oocut.createMeasurement(at: DataCapturingService.currentTimeInMillisSince1970(), inMode: defaultMode)

        try oocut.appendNewTrack(to: &measurement)
        let currentDate = Date()
        try oocut.save(locations: [TestFixture.location(), TestFixture.location(timestamp: currentDate.addingTimeInterval(10.0), isValid: false), TestFixture.location(timestamp: currentDate.addingTimeInterval(20.0))], in: &measurement)

        guard var track = measurement.tracks.last else {
            fatalError()
        }

        // Act
        let cleanTrack = try oocut.loadClean(track: &track)

        // Assert
        XCTAssertEqual(cleanTrack.count, 2)
    }

    /**
     Tests the creation, storage and retrieval of `Event` objects in `CoreData`.
    */
    func testEventCreation_HappyPath() throws {
        // Arrange
        var measurement = try oocut.createMeasurement(at: DataCapturingService.currentTimeInMillisSince1970(), inMode: defaultMode)

        // Act
        let lifecycleStartEvent = try oocut.createEvent(of: .lifecycleStart, parent: &measurement)
        sleep(1)
        let lifecycleStopEvent = try oocut.createEvent(of: .lifecycleStop, parent: &measurement)

        // Assert
        let loadedMeasurement = try oocut.load(measurementIdentifiedBy: measurement.identifier)
        let loadedEvents = loadedMeasurement.events
        XCTAssertEqual(loadedEvents[0].type, EventType.modalityTypeChange)
        XCTAssertEqual(loadedEvents[1].type, lifecycleStartEvent.type)
        XCTAssertEqual(loadedEvents[2].type, lifecycleStopEvent.type)
        XCTAssertLessThanOrEqual(Double(loadedMeasurement.timestamp) / 1_000.0, loadedEvents[1].time.timeIntervalSince1970)
        XCTAssertLessThanOrEqual(loadedEvents[1].time.timeIntervalSince1970, loadedEvents[2].time.timeIntervalSince1970)
    }

    /// Tests that loading data for upload to a Cyface data collector works as expected.
    func testLoadUploadData() throws {
        let coreDataStack = CoreDataManager(storeType: NSInMemoryStoreType, migrator: CoreDataMigrator(), modelName: "CyfaceModel", model: PersistenceTests.dataModel)
        let bundle = Bundle(for: type(of: coreDataStack))
        try coreDataStack.setup(bundle: bundle) { error in
            do {
                let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
                let measurement = try FakeMeasurementImpl.fakeMeasurement(identifier: 2).appendTrackAnd().addGeoLocationsAnd(countOfGeoLocations: 3).addAccelerations(countOfAccelerations: 60).build(persistenceLayer)

                let oocut = CoreDataBackedUpload(coreDataStack: coreDataStack, identifier: UInt64(measurement.identifier))
                let metaData = try oocut.metaData()
                let data = try oocut.data()

                XCTAssertEqual(data, try MeasurementSerializer().serializeCompressed(serializable: measurement))
                XCTAssertEqual(metaData.measurementId, UInt64(measurement.identifier))
                XCTAssertEqual(metaData.formatVersion, 3)
                XCTAssertEqual(metaData.locationCount, 3)
            } catch {
                XCTFail("\(error.localizedDescription)")
            }
        }
    }

    /// Assure that saving geo locations to a measurement actually stores them in the database.
    func testSaveLocation_HappyPath() throws {
        // Arrange
        var fixture = try XCTUnwrap(fixture)
        let currentDate = Date()
        let locations = [TestFixture.randomLocation(timestamp: currentDate), TestFixture.randomLocation(timestamp: currentDate.addingTimeInterval(10.0)), TestFixture.randomLocation(timestamp: currentDate.addingTimeInterval(20))]

        // Act
        try oocut.save(locations: locations, in: &fixture)

        // Assert
        let loadedFixture = try oocut.load(measurementIdentifiedBy: fixture.identifier)
        let loadedGeoLocations = try XCTUnwrap(loadedFixture.tracks.first?.locations)
        XCTAssertEqual(loadedGeoLocations.count, 5)
        let fixtureGeoLocations = try XCTUnwrap(fixture.tracks.first?.locations)
        XCTAssertEqual(fixtureGeoLocations.count, 5)

    }
}