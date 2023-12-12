//
//  SynchronizeMeasurementUITest.swift
//  RFRTests
//
//  Created by Klemens Muthmann on 29.11.23.
//

import XCTest
@testable import Ready_for_Robots_Development

final class SynchronizeMeasurementUITest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLoginWorks() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launchArguments = ["enable-testing"]
        app.launch()

        let loginRegisterButton = app.buttons["Anmelden oder Registrieren"]
        XCTAssert(loginRegisterButton.waitForExistence(timeout: 1))
        loginRegisterButton.tap()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssert(app.buttons["de.cyface.rfr.button.play"].waitForExistence(timeout: 1))
    }

    func testRunMeasurement() throws {
        let app = XCUIApplication()
        app.launchArguments = ["enable-testing"]
        app.launch()

        // Allow location updates
        addUIInterruptionMonitor(withDescription: "Automatically allow location permissions") { alert in
            alert.buttons["OK"].tap()
            return true
        }

        let loginRegisterButton = app.buttons["Anmelden oder Registrieren"]
        XCTAssert(loginRegisterButton.waitForExistence(timeout: 1))
        loginRegisterButton.tap()

        XCTAssert(app.buttons["de.cyface.rfr.button.play"].waitForExistence(timeout: 1))
        XCTAssert(app.buttons["de.cyface.rfr.button.play"].isEnabled)
        XCTAssert(!app.buttons["de.cyface.rfr.button.stop"].isEnabled)
        XCTAssert(!app.buttons["de.cyface.rfr.button.pause"].isEnabled)
        app.buttons["de.cyface.rfr.button.play"].tap()

        sleep(2)
        XCTAssert(!app.buttons["de.cyface.rfr.button.play"].isEnabled)
        XCTAssert(app.buttons["de.cyface.rfr.button.stop"].isEnabled)
        XCTAssert(app.buttons["de.cyface.rfr.button.pause"].isEnabled)
        app.buttons["de.cyface.rfr.button.stop"].tap()

        XCTAssert(app.buttons["de.cyface.rfr.button.play"].isEnabled)
        XCTAssert(!app.buttons["de.cyface.rfr.button.stop"].isEnabled)
        XCTAssert(!app.buttons["de.cyface.rfr.button.pause"].isEnabled)
    }

    func testPauseMeasurement() throws {
        let app = XCUIApplication()
        app.launchArguments = ["enable-testing"]
        app.launch()

        let loginRegisterButton = app.buttons["Anmelden oder Registrieren"]
        XCTAssert(loginRegisterButton.waitForExistence(timeout: 1))
        loginRegisterButton.tap()

        addUIInterruptionMonitor(withDescription: "Automatically allow location permissions") { alert in
            alert.buttons["OK"].tap()
            return true
        }

        let playButton = app.buttons["de.cyface.rfr.button.play"]
        let pauseButton = app.buttons["de.cyface.rfr.button.pause"]
        let stopButton = app.buttons["de.cyface.rfr.button.stop"]
        XCTAssert(playButton.waitForExistence(timeout: 1))
        XCTAssert(playButton.isEnabled)
        playButton.tap()
        sleep(2)

        XCTAssert(pauseButton.isEnabled)
        pauseButton.tap()
        sleep(2)
        
        XCTAssert(playButton.isEnabled)
        playButton.tap()
        sleep(2)

        XCTAssert(stopButton.isEnabled)
        stopButton.tap()
        sleep(2)

        XCTAssert(playButton.isEnabled)
        XCTAssert(!pauseButton.isEnabled)
        XCTAssert(!stopButton.isEnabled)

    }
}
