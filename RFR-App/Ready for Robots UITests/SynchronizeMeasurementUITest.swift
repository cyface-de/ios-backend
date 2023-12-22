/*
 * Copyright 2023 Cyface GmbH
 *
 * This file is part of the Ready for Robots iOS App.
 *
 * The Ready for Robots iOS App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Ready for Robots iOS App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Ready for Robots iOS App. If not, see <http://www.gnu.org/licenses/>.
 */

import XCTest
@testable import Ready_for_Robots_Development

final class SynchronizeMeasurementUITest: XCTestCase {

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
