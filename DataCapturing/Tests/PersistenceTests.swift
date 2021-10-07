/*
 * Copyright 2018 - 2021 Cyface GmbH
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
 - Version: 1.2.3
 - Since: 1.0.0
 */
class PersistenceTests: XCTestCase {

    /// A `PersistenceLayer` used for testing.
    var oocut: PersistenceLayer!
    /// Some test data.
    var fixture: Int64!
    /// The default mode of transportation used for tests.
    let defaultMode = "BICYCLE"

    /// Initializes the test enviroment by saving some test data to the test `PersistenceLayer`.
    override func setUp() {
        super.setUp()
        let expectation = self.expectation(description: "CoreDataStack initialized successfully!")
        
            let manager = CoreDataManager(storeType: NSInMemoryStoreType, migrator: CoreDataMigrator())
            let bundle = Bundle(for: type(of: manager))
            manager.setup(bundle: bundle) {
                do {
                    self.oocut = PersistenceLayer(onManager: manager)
                    self.oocut.context = self.oocut.makeContext()
                    let measurement = try self.oocut.createMeasurement(at: 10_000, inMode: self.defaultMode)
                    self.oocut.appendNewTrack(to: measurement)

                    self.fixture = measurement.identifier

                    try self.oocut.save(locations: [PersistenceTests.location(latitude: 51.052181, longitude: 13.728956, timestamp: 10_000), PersistenceTests.location(latitude: 51.051837, longitude: 13.729010, timestamp: 10_001)], in: measurement)
                    try self.oocut.save(accelerations: [PersistenceTests.acceleration(), PersistenceTests.acceleration(), PersistenceTests.acceleration()], in: measurement)

                    expectation.fulfill()
                } catch let error {
                    XCTFail("Unable to set up due to \(error.localizedDescription)")
                }
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
            let fixtureMeasurement = try oocut.load(measurementIdentifiedBy: fixture)
            try oocut.save(locations: [PersistenceTests.location()], in: fixtureMeasurement)
            try oocut.save(accelerations: [PersistenceTests.acceleration(), PersistenceTests.acceleration(), PersistenceTests.acceleration()], in: fixtureMeasurement)
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
            let fixtureMeasurement = try oocut.load(measurementIdentifiedBy: fixture)
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
            let measurement = try oocut.load(measurementIdentifiedBy: fixture)
            XCTAssertEqual(measurement.trackLength, expectedInitialTrackLength)

            let newLocationInput = [PersistenceTests.location(latitude: 51.051432, longitude: 13.729053, timestamp: 10_002)]
            try oocut.save(locations: newLocationInput, in: measurement)

            XCTAssertEqual(measurement.trackLength, expectedTrackLength, accuracy: expectedTrackLength * distanceCalculationAccuracy, "Measurement length \(measurement.trackLength) should be within \(distanceCalculationAccuracy*100)% of \(expectedTrackLength).")
        } catch let error {
            XCTFail("Error \(error.localizedDescription)")
        }
    }

    /// Tests that geo locations are added successfully to tracks and can be loaded from them.
    func testLoadGeoLocationTracks() throws {
        let measurement = try oocut.load(measurementIdentifiedBy: fixture)

        guard let tracks = measurement.tracks?.array as? [Track] else {
            return XCTFail("Unable to load tracks!")
        }
        XCTAssertEqual(tracks.count, 1, "There should only be one track in the fixture measurement!")

        guard let locations = tracks[0].locations?.array as? [GeoLocationMO] else {
            return XCTFail("Unable to load geo locations!")
        }
        XCTAssertEqual(locations.count, 2, "There should be two locations in the fixture measurement!")

        oocut.appendNewTrack(to: measurement)
        try oocut.save(locations: [PersistenceTests.location()], in: measurement)

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
        let measurement = try oocut.createMeasurement(at: DataCapturingService.currentTimeInMillisSince1970(), inMode: defaultMode)

        oocut.appendNewTrack(to: measurement)
        try oocut.save(locations: [PersistenceTests.location(), PersistenceTests.location(isValid: false), PersistenceTests.location()], in: measurement)

        guard let track = measurement.tracks?.array.last as? Track else {
            fatalError()
        }
        let cleanTrack = try oocut.loadClean(track: track)
        XCTAssertEqual(cleanTrack.count, 2)
    }

    /**
     Tests the creation, storage and retrieval of `Event` objects in `CoreData`.
    */
    func testEventCreation_HappyPath() throws {
        let measurement = try oocut.createMeasurement(at: DataCapturingService.currentTimeInMillisSince1970(), inMode: defaultMode)

        measurement.addToEvents(oocut.createEvent(of: .lifecycleStart))
        sleep(1)
        measurement.addToEvents(oocut.createEvent(of: .lifecycleStop))
        oocut.context?.saveRecursively()

        let loadedMeasurement = try oocut.load(measurementIdentifiedBy: measurement.identifier)
        let loadedEvents = loadedMeasurement.events?.array as? [Event]
        XCTAssertEqual(loadedEvents?[0].typeEnum, EventType.modalityTypeChange)
        XCTAssertEqual(loadedEvents?[1].typeEnum, EventType.lifecycleStart)
        XCTAssertEqual(loadedEvents?[2].typeEnum, EventType.lifecycleStop)
        XCTAssertLessThanOrEqual(Double(loadedMeasurement.timestamp) / 1_000.0, (loadedEvents?[1].time!.timeIntervalSince1970)!)
        XCTAssertLessThanOrEqual(loadedEvents![1].time!.timeIntervalSince1970, loadedEvents![2].time!.timeIntervalSince1970)
    }

    /**
     Create fixture data to use during testing

     - Parameters:
        - latitude: The locations latitude coordinate as a value from -90.0 to 90.0 in south and north diretion
        - longitude: The locations longitude coordinate as a value from -180.0 to 180.0 in west and east direction
        - accuracy: The estimated accuracy of the measurement in meters
        - speed: The speed the device was moving during the measurement in meters per second
        - timestamp: The time the measurement happened at in milliseconds since the 1st of january 1970
        - isValid: Whether or not this is a valid location in a cleaned track
     */
    static func location(latitude: Double = 2.0, longitude: Double = 2.0, accuracy: Double = 1.0, speed: Double = 10.0, timestamp: Int64 = 5, isValid: Bool = true) -> GeoLocation {
        return GeoLocation(latitude: latitude, longitude: longitude, accuracy: accuracy, speed: speed, timestamp: timestamp, isValid: isValid)
    }

    /**
     Create fixture acceleration
     */
    static func acceleration() -> SensorValue {
        return SensorValue(timestamp: Date(), x: 1.0, y: 1.0, z: 1.0)
    }
}
