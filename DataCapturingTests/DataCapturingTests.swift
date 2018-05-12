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
        persistenceLayer = PersistenceLayer()
        oocut = MovebisServerConnection(apiURL: URL(string: "https://localhost:8080")!, persistenceLayer: persistenceLayer!)
    }

    override func tearDown() {
        oocut = nil
        super.tearDown()
    }

    func testSynchronizationWithMovebisServer() {
        guard let oocut = oocut else {
            fatalError("Test failed!")
        }

        let persistenceLayer = PersistenceLayer()
        let measurement = persistenceLayer.createMeasurement(at: 2)
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
