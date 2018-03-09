//
//  DataCapturingTests.swift
//  DataCapturingTests
//
//  Created by Team Cyface on 07.11.17.
//  Copyright © 2017 Cyface GmbH. All rights reserved.
//

import XCTest
@testable import DataCapturing

class DataCapturingTests: XCTestCase {

    var oocut: MovebisServerConnection?

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        oocut = MovebisServerConnection(apiURL: URL(string: "https://localhost:8080")!)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        oocut = nil
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        guard let oocut = oocut else {
            fatalError("Test failed!")
        }

        let pl = PersistenceLayer()
        let measurement = pl.createMeasurement(at: 2)
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

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
