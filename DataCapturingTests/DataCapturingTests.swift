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
@testable import DataCapturing

/**
 This test is intended to test capturing some data in isolation. There are still some problems with this, due to restrictions in Apple's test support.

 - Author: Klemens Muthmann
 - Version: 1.0.3
 - Since: 1.0.0
 */
class DataCapturingTests: XCTestCase {

    /// A connection to a Cyface Server backend.
    var oocut: ServerConnection!
    /// A `PersistenceLayer` providing access to write and read some example data.
    var persistenceLayer: PersistenceLayer!
    var authenticator: StaticAuthenticator!

    override func setUp() {
        super.setUp()

        do {
            persistenceLayer = try PersistenceLayer(withDistanceCalculator: DefaultDistanceCalculationStrategy())
        } catch let error {
            fatalError("Failed to initialize persistence layer: \(error.localizedDescription)")
        }

        authenticator = StaticAuthenticator()
        oocut = ServerConnection(apiURL: URL(string: "https://localhost:8080")!, authenticator: authenticator!)
    }

    override func tearDown() {
        oocut = nil
        persistenceLayer = nil
        authenticator = nil
        super.tearDown()
    }

    /**
     This test tests the actual upload of data to a Movebis server. Since we can not assume there is one such server in each and every test environment (especially under CI conditions), the test is skipped by default. Enable it to selectively test data upload in isolation. The test should also not run on an arbitrary server, since most servers will reject the transmitted data on the second run, because of data duplication.
     */
    func skipped_testSynchronizationWithMovebisServer() {
        let promise = expectation(description: "Successful data transmission")
        do {
            let measurement = try persistenceLayer.createMeasurement(at: 2, withContext: .bike)

            self.authenticator!.jwtToken = "replace me"

            let entity = MeasurementEntity(identifier: measurement.identifier, context: MeasurementContext(rawValue: measurement.context!)!)
            oocut.sync(measurement: entity, onSuccess: {submitted in
                XCTAssertEqual(submitted.identifier, entity.identifier)
                promise.fulfill()
            }, onFailure: {_, error in
                XCTFail("Error \(error)")
                promise.fulfill()
            })
        } catch let error {
            XCTFail("Synchronization produced an error! \(error)")
        }

        wait(for: [promise], timeout: 10)
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
        - `PersistenceError.modelNotLoabable` If the model is not loadable
        - `PersistenceError.modelNotInitializable` If the model was loaded (so it is available) but can not be initialized.
        - `SynchronizationError.reachabilityNotInitilized`: If the synchronizer was unable to initialize the reachability service that surveys the Wifi connection and starts synchronization if Wifi is available.
        - `DataCapturingError.isPaused` If the service was paused and thus it makes no sense to start it.
        - `DataCapturingError.isPaused` If the service was paused and thus stopping it makes no sense.
        - `PersistenceError.noContext` If there is no current context and no background context can be created. If this happens something is seriously wrong with CoreData.
        - Some unspecified errors from within CoreData.
     */
    func skip_testLoadOnlyInactiveMeasurement_HappyPath() throws {
        // Arrange
        let serverConnection = ServerConnection(apiURL: URL(string: "http://localhost")!, authenticator: StaticAuthenticator())
        let sensorManager = CMMotionManager()
        let persistenceLayer = try PersistenceLayer(withDistanceCalculator: DefaultDistanceCalculationStrategy())
        let dcs = try MovebisDataCapturingService(connection: serverConnection, sensorManager: sensorManager, persistenceLayer: persistenceLayer) { _, _ in

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
