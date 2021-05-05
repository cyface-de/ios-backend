//
//  SensorCapturerTest.swift
//  Tests
//
//  Created by Klemens Muthmann on 05.05.21.
//  Copyright © 2021 Cyface GmbH. All rights reserved.
//

import XCTest
import CoreMotion
@testable import DataCapturing

class SensorCapturerTest: XCTestCase {
    
    func testCapturedAccelerometerTimestamps() throws {
        // Arrange
        let motionManager = CMMotionManager()
        try XCTSkipUnless(motionManager.isAccelerometerAvailable)
        
        let sensorCapturer = SensorCapturer(lifecycleQueue: DispatchQueue.global(), capturingQueue: DispatchQueue.global(), motionManager: motionManager)
        let expectation = self.expectation(description: "Captured some data!")
        sensorCapturer.start()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            sensorCapturer.stop()
            XCTAssertFalse(sensorCapturer.accelerations.isEmpty)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10) {error in
            if let error = error {
                XCTFail("SensorCapturerTest failed \(error)")
            }
        }
    }
    
}
