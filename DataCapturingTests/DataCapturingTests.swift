//
//  DataCapturingTests.swift
//  DataCapturingTests
//
//  Created by Team Cyface on 07.11.17.
//  Copyright © 2017 Cyface GmbH. All rights reserved.
//

import XCTest
import CoreMotion
@testable import DataCapturing

class DataCapturingTests: XCTestCase {

    var oocut: MovebisServerConnection?
    var persistenceLayer: PersistenceLayer?

    override func setUp() {
        super.setUp()
        let syncGroup = DispatchGroup()
        syncGroup.enter()
        persistenceLayer = PersistenceLayer() {
            syncGroup.leave()
        }
        guard syncGroup.wait(timeout: DispatchTime.now() + .seconds(2)) == .success else {
            fatalError("Failed to initialize persistence layer.")
        }

        oocut = MovebisServerConnection(apiURL: URL(string: "https://localhost:8080")!, persistenceLayer: persistenceLayer!)
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

        let measurement = persistenceLayer.createMeasurement(at: 2, withContext: .bike)
        let promise = expectation(description: "No error on synchronization!")

        oocut.authenticate(withJwtToken: "replace me")
        oocut.sync(measurement: measurement) { _, error in
            if error==nil {
                promise.fulfill()
            } else {
                XCTFail("Synchronization produced an error!")
            }
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
