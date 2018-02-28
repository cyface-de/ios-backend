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
        
        oocut.authenticate(withJwtToken: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJyZWYiOiI1YTgyZDU4ODE1MjAwIiwiZ2VuZGVyIjoibWFsZSIsImFnZSI6NTB9.hr2OFMrzRGEIE2544NzrfifL0n22yE5Xz1jl8EDPh9n6PfTbU_znac6bgbzof3R9TJ9EFp2jyU9fI5rp7rNlFxomu-ORaUSMSktZEHMsC6_h7TVAw0Ygp3jS76-YODlw9VjWmj__5qcqYlQ47ywEYv5uHqXecPt3I2rUtGcLsBm7Gb1eKBwxymi_pEivpo0IIiRIfDv4fYM3IB6cosL7zHFO-nDXRz3IXO3KUwljbieZMng50zCuEiN3DVME-QF1GO3PhO_4M4vTq8_uWx62WxCr2UX28U5DJepJSddDsn5VvzfGAPXB7AF5uh33mtDWkRYnA9KrXSpqeE47TkomntfQg5SV4z0CPbr-d9ThN6cynC83kvh2Up5_DA1nF8kqDibX8hIHmQu5eqG8fgLRjJEHFXLOil-Us9i-oWVhNMv8zYBOCsgJErcAOO9TvbFuoTZt1UYyFLovmOIsBHb54A3xLmlGRQy4ClpaCRdtmopz6Y7VCEN5rjXR57L1tRrPgCrOtzEs05wbnvpYWg_5it4Jx8CyzqMC4t2jHqqfRQNq9enRbp2v9Y1GfCQtFP6XB5hi5grGfh8MfHt0JQ-VQ0NYgNVYp_AKf40wz8ygOvLRDdIqBtMeZGU6ZhOPcy-lzl8SZzXtcwBwPH3POL-4qYGexGHjaM0vhWwym2nIfhY")
        oocut.sync(measurement: measurement) { error in
            if(error==nil) {
                promise.fulfill()
            } else {
                XCTFail()
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
