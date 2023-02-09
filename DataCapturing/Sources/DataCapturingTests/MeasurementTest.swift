//
//  MeasurementTest.swift
//  
//
//  Created by Klemens Muthmann on 02.02.23.
//

import XCTest
@testable import DataCapturing

final class MeasurementTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() async throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        let coreDataStack = await CoreDataStack()
        let oocut = try await Measurement(coreDataStack)
        oocut.subscribe(testSubscriber)

        try await oocut.start()

        try await oocut.pause()

        try await oocut.resume()

        try await oocut.stop()

        // TODO. There should probably be some fix and geo location events as well.
        XCTAssertEqual(testSubscriber.events[0], DataCapturingEvent.serviceStarted)
        XCTAssertEqual(testSubscriber.events[1], DataCapturingEvent.servicePaused)
        XCTAssertEqual(testSubscriber.events[2], DataCapturingEvent.serviceResumed)
        XCTAssertEqual(testSubscriber.events[3], DataCapturingEvent.serviceStopped)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
