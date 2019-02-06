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
 - Version: 1.0.1
 - Since: 1.0.0
 */
class DataCapturingTests: XCTestCase {

    /// A connection to a Cyface Server backend.
    var oocut: ServerConnection?
    /// A `PersistenceLayer` providing access to write and read some example data.
    var persistenceLayer: PersistenceLayer?
    var authenticator: StaticAuthenticator?

    override func setUp() {
        super.setUp()
        let syncGroup = DispatchGroup()
        syncGroup.enter()
        persistenceLayer = PersistenceLayer { _ in
            syncGroup.leave()
        }
        guard syncGroup.wait(timeout: DispatchTime.now() + .seconds(2)) == .success else {
            fatalError("Failed to initialize persistence layer.")
        }

        authenticator = StaticAuthenticator()
        oocut = ServerConnection(apiURL: URL(string: "https://localhost:8080")!, persistenceLayer: persistenceLayer!, authenticator: authenticator!)
    }

    override func tearDown() {
        oocut = nil
        super.tearDown()
    }

    /**
     This test tests the actual upload of data to a Movebis server. Since we can not assume there is one such server in each and every test environment (especially under CI conditions), the test is skipped by default. Enable it to selectively test data upload in isolation. The test should also not run on an arbitrary server, since most servers will reject the transmitted data on the second run, because of data duplication.
     */
    func skipped_testSynchronizationWithMovebisServer() {
        guard let oocut = oocut, let persistenceLayer = persistenceLayer else {
            fatalError("Test failed!")
        }

        let promise = expectation(description: "No error on synchronization!")
        persistenceLayer.createMeasurement(at: 2, withContext: .bike) { measurementMo in

            self.authenticator!.jwtToken = "replace me"

            let successHandler: ((MeasurementEntity) -> Void) = { _ in
                promise.fulfill()
            }
            let failureHandler: ((MeasurementEntity, Error) -> Void) = { _, _ in
                XCTFail("Synchronization produced an error!")
            }

            let measurement = MeasurementEntity(identifier: measurementMo.identifier, context: MeasurementContext(rawValue: measurementMo.context!)!)
            oocut.sync(measurement: measurement, onSuccess: successHandler, onFailure: failureHandler)
        }

        waitForExpectations(timeout: 10, handler: nil)
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
}
