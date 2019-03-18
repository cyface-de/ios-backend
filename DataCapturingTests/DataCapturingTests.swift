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
 This test is intended to test capturing some data in isolation. There are still some problems with this, due to restrictions in Apple's test support.

 - Author: Klemens Muthmann
 - Version: 1.1.0
 - Since: 1.0.0
 */
class DataCapturingTests: XCTestCase {

    /// A connection to a Cyface Server backend.
    var oocut: TestDataCapturingService!
    var authenticator: StaticAuthenticator!

    override func setUp() {
        super.setUp()

        do {
            let persistenceLayer = try PersistenceLayer(withDistanceCalculator: DefaultDistanceCalculationStrategy())
            let sensorManager = TestMotionManager()
            oocut = TestDataCapturingService(sensorManager: sensorManager, persistenceLayer: persistenceLayer, synchronizer: nil) { event, status in }
        } catch let error {
            fatalError("Failed to initialize persistence layer: \(error.localizedDescription)")
        }
    }

    /// Tears down the test environment.
    override func tearDown() {
        authenticator = nil
        super.tearDown()
    }

    func testStartStop_HappyPath() throws {
        try oocut.start(inContext: .bike)
        try oocut.stop()
    }

    func testStartPauseResumeStop_HappyPath() throws {
        try oocut.start(inContext: .bike)
        try oocut.pause()
        try oocut.resume()
        try oocut.stop()
    }

    func testDoubleStart() throws {
        try oocut.start(inContext: .bike)
        try oocut.start(inContext: .bike)
        try oocut.stop()
    }

    func testDoubleResume() throws {
        try oocut.start(inContext: .bike)
        try oocut.pause()
        try oocut.resume()
        try oocut.resume()
        try oocut.stop()
    }

    func testDoublePause() throws {
        try oocut.start(inContext: .bike)
        try oocut.pause()
        try oocut.pause()
        try oocut.resume()
        try oocut.stop()
    }

    func testDoubleStop() throws {
        try oocut.start(inContext: .bike)
        try oocut.stop()
        try oocut.stop()
    }

    func testPauseFromIdle() throws {
        try oocut.pause()
    }

    func testResumeFromIdle() throws {
        try oocut.stop()
    }

    func testStopFromIdle() throws {
        try oocut.stop()
    }

    func testLifecyclePerformance() throws {
        measure {
            oocut.locationsCache = [GeoLocation(latitude: 1.0, longitude: 1.0, accuracy: 1.0, speed: 1.0, timestamp: 10_000)]
            oocut.accelerationsCache = []
            for i in 0...99 {
            oocut.accelerationsCache.append(Acceleration(timestamp: 10_000 + Int64(i), x: 1.0, y: 1.0, z: 1.0))
            }
            oocut.saveCapturedData()
        }
    }

// TODO: This test does not work since we can not test with background location updates in the moment.
/*func testCaptureData() {
guard let oocut = oocut else {
XCTFail("Unable to get server connection object.")
return
}
let persistenceLayer = PersistenceLayer()
let sensorManager = CMMotionManager()
let dataCapturingService = MovebisDataCapturingService(connection: oocut, sensorManager: sensorManager, updateInterval: 0.0, persistenceLayer: persistenceLayer)

dataCapturingService.start()
XCTAssertTrue(dataCapturingService.isRunning)
let prePauseCountOfMeasurements = dataCapturingService.countMeasurements()

dataCapturingService.pause()
XCTAssertFalse(dataCapturingService.isRunning)

dataCapturingService.resume()
XCTAssertTrue(dataCapturingService.isRunning)
let postPauseCountOfMeasurements = dataCapturingService.countMeasurements()
XCTAssertEqual(prePauseCountOfMeasurements, postPauseCountOfMeasurements)

dataCapturingService.stop()
XCTAssertFalse(dataCapturingService.isRunning)
}*/

// TODO: (STAD-104) This does currently not work as a test case is not allowed to run background location updates.
/**
Tests whether loading only inactive measurements on the `MovebisDataCapturingService` works as expected.

- Throws:
- `SynchronizationError.reachabilityNotInitilized`: If the synchronizer was unable to initialize the reachability service that surveys the Wifi connection and starts synchronization if Wifi is available.
- `DataCapturingError.isPaused` If the service was paused and thus it makes no sense to start it.
- `DataCapturingError.isPaused` If the service was paused and thus stopping it makes no sense.
- `PersistenceError.noContext` If there is no current context and no background context can be created. If this happens something is seriously wrong with CoreData.
- Some unspecified errors from within CoreData.
*/
func skip_testLoadOnlyInactiveMeasurement_HappyPath() throws {
// Arrange
let sensorManager = CMMotionManager()
let dcs = try MovebisDataCapturingService(connection: oocut, sensorManager: sensorManager, dataManager: dataManager) { _, _ in

}

// Act
// 1st Measurement
try dcs.start()
try dcs.stop()

// 2nd Measurement
try dcs.start()
try dcs.stop()

// 3rd Measurement
try dcs.start()

// Assert
XCTAssertEqual(try dcs.loadInactiveMeasurements().count, 2)
}
}
