/*
 * Copyright 2017 Cyface GmbH
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
import CoreMotion
import CoreData
@testable import DataCapturing

/**
 This test is intended to test capturing some data in isolation.

 - Author: Klemens Muthmann
 - Version: 2.2.0
 - Since: 1.0.0
 */
class DataCapturingTests: XCTestCase {

    /// The object of the class under test. This `DataCapturingService` is a `TestDataCapturingService` simulating all sensor updates.
    var oocut: TestDataCapturingService!
    /// The *CoreData* stack to access and check data create by lifecycle methods.
    var coreDataStack: CoreDataManager!

    /// Initializes every test by creating a `TestDataCapturingService`.
    override func setUp() {
        super.setUp()

        guard let bundle = Bundle(identifier: "de.cyface.DataCapturing") else {
            fatalError()
        }

        coreDataStack = CoreDataManager(storeType: NSInMemoryStoreType, migrator: CoreDataMigrator())
        coreDataStack.setup(bundle: bundle)

        oocut = dataCapturingService(dataManager: coreDataStack)
    }

    /// Tears down the test environment.
    override func tearDown() {
        // Wait for write operations to have finished! This is necessary to delete the data again.
        oocut = nil
        let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
        persistenceLayer.context = persistenceLayer.makeContext()
        do {
            // Handle this in its own thread to avoid race conditions.
            //try syncQueue.sync {
                try persistenceLayer.delete()
            //}
        } catch {
            fatalError("\(error)")
        }
        coreDataStack = nil
        super.tearDown()
    }

    /**
     Checks correct workings of a simple start/stop lifecycle.

     - Throws:
        - `DataCapturingError.isPaused` if the service was paused and thus starting or stopping it makes no sense. If you need to continue call `resume(((DataCapturingEvent) -> Void))`.
     */
    func testStartStop_HappyPath() throws {
        try oocut.start(inContext: .bike)
        XCTAssertTrue(oocut.isRunning)
        XCTAssertFalse(oocut.isPaused)
        try oocut.stop()
        XCTAssertFalse(oocut.isRunning)
        XCTAssertFalse(oocut.isPaused)
    }

    /**
     Checks the correct execution of a typical lifecylce with a pause in between.

     - Throws:
        - `DataCapturingError.isPaused` if the service was paused and thus starting, pausing it again or stopping it makes no sense. If you need to continue call `resume(((DataCapturingEvent) -> Void))`.
        - `DataCapturingError.notRunning` if the service was not running and thus pausing it makes no sense.
        - `DataCapturingError.notPaused`: If the service was not paused and thus resuming it makes no sense.
        - `DataCapturingError.isRunning`: If the service was running and thus resuming it makes no sense.
        - `DataCapturingError.noCurrentMeasurement`: If no current measurement is available while resuming data capturing.
     */
    func testStartPauseResumeStop_HappyPath() throws {
        let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
        persistenceLayer.context = persistenceLayer.makeContext()

        try oocut.start(inContext: .bike)
        XCTAssertTrue(oocut.isRunning)
        XCTAssertFalse(oocut.isPaused)
        let prePauseCountOfMeasurements = try persistenceLayer.countMeasurements()
        let measurementIdentifier = oocut.currentMeasurement!

        try oocut.pause()
        XCTAssertFalse(oocut.isRunning)
        XCTAssertTrue(oocut.isPaused)
        try oocut.resume()
        let postPauseCountOfMeasurements = try persistenceLayer.countMeasurements()
        XCTAssertEqual(prePauseCountOfMeasurements, postPauseCountOfMeasurements)
        XCTAssertTrue(oocut.isRunning)
        XCTAssertFalse(oocut.isPaused)
        try oocut.stop()
        XCTAssertFalse(oocut.isRunning)
        XCTAssertFalse(oocut.isPaused)

        let measurement = try persistenceLayer.load(measurementIdentifiedBy: measurementIdentifier)
        let events = measurement.events!.array as! [Event]
        XCTAssertEqual(events.count, 5)
        XCTAssertEqual(events[1].typeEnum, .lifecycleStart)
        XCTAssertEqual(events[2].typeEnum, .lifecyclePause)
        XCTAssertEqual(events[3].typeEnum, .lifecycleResume)
        XCTAssertEqual(events[4].typeEnum, .lifecycleStop)
    }

    func testStartPauseStop_HappyPath() throws {
        let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
        persistenceLayer.context = persistenceLayer.makeContext()
        let preStartCountOfMeasurements = try persistenceLayer.countMeasurements()

        try oocut.start(inContext: .bike)
        XCTAssertTrue(oocut.isRunning)
        XCTAssertFalse(oocut.isPaused)
        let postStartCountOfMeasurements = try persistenceLayer.countMeasurements()
        XCTAssertTrue(postStartCountOfMeasurements == preStartCountOfMeasurements + 1)

        try oocut.pause()
        XCTAssertFalse(oocut.isRunning)
        XCTAssertTrue(oocut.isPaused)

        try oocut.stop()
        XCTAssertFalse(oocut.isRunning)
        XCTAssertFalse(oocut.isPaused)
    }

    /**
     Checks that calling `start` twice causes no errors and is gracefully ignored.

     - Throws:
        - `DataCapturingError.isPaused` if the service was paused and thus starting or stopping it makes no sense. If you need to continue call `resume(((DataCapturingEvent) -> Void))`.
     */
    func testDoubleStart() throws {
        try oocut.start(inContext: .bike)
        XCTAssertTrue(oocut.isRunning)
        XCTAssertFalse(oocut.isPaused)
        try oocut.start(inContext: .bike)
        XCTAssertTrue(oocut.isRunning)
        XCTAssertFalse(oocut.isPaused)
        try oocut.stop()
        XCTAssertFalse(oocut.isRunning)
        XCTAssertFalse(oocut.isPaused)
    }

    /**
     Checks that calling resume on a stopped service twice causes the appropriate `DataCapturingError` and leaves the `DataCapturingService` in a state where stopping is still possible.

     - Throws:
        - `DataCapturingError.isPaused` if the service was paused and thus starting, pausing it again or stopping it makes no sense. If you need to continue call `resume(((DataCapturingEvent) -> Void))`.
        - `DataCapturingError.notRunning` if the service was not running and thus pausing it makes no sense.
        - `DataCapturingError.notPaused`: If the service was not paused and thus resuming it makes no sense.
        - `DataCapturingError.isRunning`: If the service was running and thus resuming it makes no sense.
        - `DataCapturingError.noCurrentMeasurement`: If no current measurement is available while resuming data capturing.
     */
    func testDoubleResume() throws {
        try oocut.start(inContext: .bike)
        XCTAssertTrue(oocut.isRunning)
        XCTAssertFalse(oocut.isPaused)
        try oocut.pause()
        XCTAssertFalse(oocut.isRunning)
        XCTAssertTrue(oocut.isPaused)
        try oocut.resume()
        XCTAssertTrue(oocut.isRunning)
        XCTAssertFalse(oocut.isPaused)
        XCTAssertThrowsError(try oocut.resume()) { error in
            XCTAssertTrue(error is DataCapturingError)
            XCTAssertTrue(oocut.isRunning)
            XCTAssertFalse(oocut.isPaused)
        }
        try oocut.stop()
        XCTAssertFalse(oocut.isRunning)
        XCTAssertFalse(oocut.isPaused)
    }

    /**
     Checks that pausing the service multiple times causes the appropriate `DataCapturingError` and leave the service in a state, where it can still be resumed.

     - Throws:
        - `DataCapturingError.isPaused` if the service was paused and thus starting, pausing it again or stopping it makes no sense. If you need to continue call `resume(((DataCapturingEvent) -> Void))`.
        - `DataCapturingError.notRunning` if the service was not running and thus pausing it makes no sense.
        - `DataCapturingError.notPaused`: If the service was not paused and thus resuming it makes no sense.
        - `DataCapturingError.isRunning`: If the service was running and thus resuming it makes no sense.
        - `DataCapturingError.noCurrentMeasurement`: If no current measurement is available while resuming data capturing.
     */
    func testDoublePause() throws {
        try oocut.start(inContext: .bike)
        XCTAssertTrue(oocut.isRunning)
        try oocut.pause()
        XCTAssertFalse(oocut.isRunning)
        XCTAssertTrue(oocut.isPaused)
        XCTAssertThrowsError(try oocut.pause(), "Calling pause twice should throw an error!") { error in
            XCTAssertTrue(error is DataCapturingError)
            XCTAssertFalse(oocut.isRunning)
            XCTAssertTrue(oocut.isPaused)
        }
        try oocut.resume()
        XCTAssertTrue(oocut.isRunning)
        XCTAssertFalse(oocut.isPaused)
        try oocut.stop()
        XCTAssertFalse(oocut.isRunning)
        XCTAssertFalse(oocut.isPaused)
    }

    /**
     Checks that stopping a running service multiple times causes no errors and leaves the service in the expected stopped state.

     - Throws:
        - `DataCapturingError.isPaused` if the service was paused and thus starting it makes no sense. If you need to continue call `resume(((DataCapturingEvent) -> Void))`.
        - `DataCapturingError.isPaused` if the service was paused and thus stopping it makes no sense.
     */
    func testDoubleStop() throws {
        try oocut.start(inContext: .bike)
        XCTAssertTrue(oocut.isRunning)
        XCTAssertFalse(oocut.isPaused)
        try oocut.stop()
        XCTAssertFalse(oocut.isRunning)
        XCTAssertFalse(oocut.isPaused)
        try oocut.stop()
        XCTAssertFalse(oocut.isRunning)
        XCTAssertFalse(oocut.isPaused)
    }

    /// Checks that pausing a not started service results in an exception and does not change the `DataCapturingService` state.
    func testPauseFromIdle() {
        XCTAssertThrowsError(try oocut.pause(), "Pausing a non running service, should throw an error!") { error in
            XCTAssertTrue(error is DataCapturingError, "Error should be a DataCapturingError!")
            XCTAssertFalse(oocut.isRunning)
            XCTAssertFalse(oocut.isPaused)
        }
    }

    /// Checks that resuming a not started service results in an exception and does not change the `DataCapturingService` state.
    func testResumeFromIdle() {
        XCTAssertThrowsError(try oocut.resume(), "Resuming a non paused service, should throw an error!") { error in
            XCTAssertTrue(error is DataCapturingError, "Error should be a DataCapturingError!")
            XCTAssertFalse(oocut.isRunning)
            XCTAssertFalse(oocut.isPaused)
        }
    }

    /**
     Checks that stopping a stopped service causes no errors and leave the `DataCapturingService` in a stopped state

     - Throws:
        - `DataCapturingError.isPaused` if the service was paused and thus stopping it makes no sense.
    */
    func testStopFromIdle() throws {
        try oocut.stop()
        XCTAssertFalse(oocut.isPaused)
        XCTAssertFalse(oocut.isRunning)
    }

    /**
    Tests the performance of saving a batch of measurement data during data capturing.
    This time must never exceed the time it takes to capture that data.

     - Throws:
        - PersistenceError.measurementNotCreatable(timestamp) If CoreData was unable to create the new entity.
        - PersistenceError.noContext If there is no current context and no background context can be created. If this happens something is seriously wrong with CoreData.
        - Some unspecified errors from within CoreData.
     */
    func testLifecyclePerformance() throws {
        let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
        persistenceLayer.context = persistenceLayer.makeContext()
        let measurement = try persistenceLayer.createMeasurement(at: DataCapturingService.currentTimeInMillisSince1970(), withContext: .bike)
        oocut.currentMeasurement = measurement.identifier

        measure {
            oocut.locationsCache = [GeoLocation(latitude: 1.0, longitude: 1.0, accuracy: 1.0, speed: 1.0, timestamp: 10_000, isValid: true)]
            oocut.accelerationsCache = []
            for i in 0...99 {
                oocut.accelerationsCache.append(Acceleration(timestamp: 10_000 + Int64(i), x: 1.0, y: 1.0, z: 1.0))
            }
            oocut.saveCapturedData()
        }
    }

    /**
     Tests whether using a reduced update interval for location update events, works as expected.

     - Throws:
        - `PersistenceError` If the currently captured measurement was not found in the database.
        - Some unspecified errors from within *CoreData*.
     */
    func testWithLowerUpdateInterval_HappyPath() throws {
        // Arrange
        var updateCounter = 0
        let async = expectation(description: "Geo Location events")
        let testCapturingService = dataCapturingService(dataManager: coreDataStack) { (event, _) in
                if case DataCapturingEvent.geoLocationAcquired(_) = event {
                    updateCounter += 1
                    if updateCounter == 2 {
                        async.fulfill()
                    }
                }
        }
        testCapturingService.coreLocationManager = TestLocationManager()
        testCapturingService.locationUpdateSkipRate = 5

        // Act
        try testCapturingService.start(inContext: .bike)

        wait(for: [async], timeout: 20)
        try testCapturingService.stop()

        // Assert
        XCTAssertEqual(updateCounter, 2)
        let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
        persistenceLayer.context = persistenceLayer.makeContext()

        guard let locationsCount = (try persistenceLayer.loadMeasurements()[0].tracks?.firstObject as? Track)?.locations?.count else {
            fatalError("Unable to load created locations")
        }
        print(locationsCount)
        XCTAssertTrue(locationsCount>=5)
    }

    /// Tests that the distance calculation always contains the last segment of a capturing run.
    func testStartPauseResumeStop_DistanceCalculationContainsLastSegment() throws {
        let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
        persistenceLayer.context = persistenceLayer.makeContext()
        try oocut.start(inContext: .bike)
        guard let currentMeasurementIdentifier = oocut.currentMeasurement else {
            fatalError()
        }

        // TODO: Make it possible to inject geo locations to avoid these sleep calls.
        sleep(2)
        try oocut.pause()
        let measurement = try persistenceLayer.load(measurementIdentifiedBy: currentMeasurementIdentifier)
        let trackLengthAfterPause = measurement.trackLength
        try oocut.resume()
        sleep(2)
        try oocut.stop()
        let measurementAfterStop = try persistenceLayer.load(measurementIdentifiedBy: currentMeasurementIdentifier)
        let trackLengthAfterStop = measurementAfterStop.trackLength

        XCTAssertTrue(trackLengthAfterStop>=trackLengthAfterPause)
    }

    /// After the App has been paused very long iOS will kill it. This deletes the paused state in memory. This test checks that recreating this state from the database is successful.
    func testResumeAfterLongPause_ShouldNotThrowAnException() throws {
        try oocut.start(inContext: .bike)
        try oocut.pause()

        let newOocut = dataCapturingService(dataManager: coreDataStack)
        do {
            try newOocut.resume()
        } catch {
            XCTFail("Encountered exception \(error) on new instance.")
        }
        try newOocut.stop()
    }

    /// In case there already is a paused measurement after App restart, starting should still be successful and just output a warning.
    func testStartPausedService_FinishesPausedMeasurementAndThrowsNoException() throws {
        try oocut.start(inContext: .bike)
        try oocut.pause()

        let newOocut = dataCapturingService(dataManager: coreDataStack)
        XCTAssertTrue(newOocut.isPaused)
        do {
            try newOocut.start(inContext: .bike)
        } catch {
            XCTFail("Encountered exception \(error) on new instance.")
        }
        try newOocut.stop()
    }

    func testChangeModality_EventLogContainsTwoModalities() throws {
        // Act
        try oocut.start(inContext: .bike)
        guard let currentMeasurementIdentifier = oocut.currentMeasurement else {
            return XCTFail("Unable to load current measurement from running data capturing service!")
        }
        oocut.changeModality(to: .car)
        try oocut.stop()

        // Assert
        let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
        persistenceLayer.context = persistenceLayer.makeContext()
        let capturedMeasurement = try persistenceLayer.load(measurementIdentifiedBy: currentMeasurementIdentifier)
        let modalityChangeEvents = try persistenceLayer.loadEvents(typed: .modalityTypeChange, forMeasurement: capturedMeasurement)
        XCTAssertEqual(modalityChangeEvents.count, 2)
        XCTAssertEqual(modalityChangeEvents[1].value, Modality.bike.rawValue)
        XCTAssertEqual(modalityChangeEvents[0].value, Modality.car.rawValue)
    }

    func testChangeModalityToSameModalityTwice_EventLogStillContainsOnlyTwoModalities() throws {
        // Act
        try oocut.start(inContext: .bike)
        guard let currentMeasurementIdentifier = oocut.currentMeasurement else {
            return XCTFail("Unable to load current measurement from running data capturing service!")
        }
        oocut.changeModality(to: .car)
        oocut.changeModality(to: .car)
        try oocut.stop()

        // Assert
        let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
        persistenceLayer.context = persistenceLayer.makeContext()
        let capturedMeasurement = try persistenceLayer.load(measurementIdentifiedBy: currentMeasurementIdentifier)
        let modalityChangeEvents = try persistenceLayer.loadEvents(typed: .modalityTypeChange, forMeasurement: capturedMeasurement)
        XCTAssertEqual(modalityChangeEvents.count, 2)
        XCTAssertEqual(modalityChangeEvents[1].value, Modality.bike.rawValue)
        XCTAssertEqual(modalityChangeEvents[0].value, Modality.car.rawValue)
    }

    func testChangeModalityWhilePaused_EventLogStillContainsModalityChange() throws {
        // Act
        try oocut.start(inContext: .bike)
        guard let currentMeasurementIdentifier = oocut.currentMeasurement else {
            return XCTFail("Unable to load current measurement from running data capturing service!")
        }
        try oocut.pause()
        oocut.changeModality(to: .car)
        try oocut.resume()
        try oocut.stop()

        // Assert
        let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
        persistenceLayer.context = persistenceLayer.makeContext()
        let capturedMeasurement = try persistenceLayer.load(measurementIdentifiedBy: currentMeasurementIdentifier)
        let modalityChangeEvents = try persistenceLayer.loadEvents(typed: .modalityTypeChange, forMeasurement: capturedMeasurement)
        XCTAssertEqual(modalityChangeEvents.count, 2)
        XCTAssertEqual(modalityChangeEvents[1].value, Modality.bike.rawValue)
        XCTAssertEqual(modalityChangeEvents[0].value, Modality.car.rawValue)
    }

    /**
     Creates a new `DataCapturingService` initialized for testing, which means all sensors are mocked.

     - Parameters:
        - sensorManager: The iOS `CMMotionManager` to use. The default is a `TestMotionManager`, which prevents accessing the actual sensors and only returns random values.
        - dataManager: A `CoreDataManager` used to access the database to write or read data.
        - eventHandler: An `eventHandler` used to capture events from the created service. The default implementation is a no-op implementation throwing all events away.
     */
    func dataCapturingService(sensorManager: CMMotionManager = TestMotionManager(), dataManager: CoreDataManager, eventHandler: @escaping ((DataCapturingEvent, Status) -> Void) = {_, _ in }) -> TestDataCapturingService {
        let ret = TestDataCapturingService(sensorManager: sensorManager, dataManager: dataManager, eventHandler: eventHandler)
        ret.coreLocationManager = TestLocationManager()
        return ret
    }
}
