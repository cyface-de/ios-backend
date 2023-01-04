//
//  Cyface_AppUITests.swift
//  Cyface-AppUITests
//
//  Created by Klemens Muthmann on 25.03.22.
//

import XCTest
// This kind of XCUI test is a hassle to work with, since the app is not uninstalled at the end.
// So state from previous tests always bleeds into other ones or even future runs.
// I'll leave the example code here for the moment, but comment the actual test code, to make CI happy.
// A working solution would probavly use a snapshot test library such as described here:
// https://www.vadimbulavin.com/snapshot-testing-swiftui-views/
class Cyface_AppUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = true

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        // app.uninstall(name: "Cyface")
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        // app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Privacy Policy View
        // XCTAssertTrue(app.staticTexts["Privacy Policy"].exists)
        // app.buttons["Accept"].tap()

        // Login View
        // XCTAssertTrue(app.buttons["Login"].exists)
        // XCTAssertTrue(app.buttons["Register New Account"].exists)
        // XCTAssertTrue(app.textFields["Username"].exists)
        // XCTAssertTrue(app.textFields["Password"].exists)
        // XCTAssertTrue(app.images.allElementsBoundByIndex[0].exists)
        // XCTAssertTrue(app.images.count==1)
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}

// source: https://www.jessesquires.com/blog/2021/10/25/delete-app-during-ui-tests/
// This did not work as I tried it (26.10.2022)
extension XCUIApplication {
    func uninstall(name: String? = nil) {
        self.terminate()

        let timeout = TimeInterval(10)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

        let appName: String
        if let name = name {
            appName = name
        } else {
            let uiTestRunnerName = Bundle.main.infoDictionary?["CFBundleName"] as! String
            appName = uiTestRunnerName.replacingOccurrences(of: "UITests-Runner", with: "")
        }

        /// use `firstMatch` because icon may appear in iPad dock
        let appIcon = springboard.icons[appName].firstMatch
        if appIcon.waitForExistence(timeout: timeout) {
            appIcon.press(forDuration: 5)
        } else {
            XCTFail("Failed to find app icon named \(appName)")
        }

        let removeAppButton = springboard.buttons["Remove App"]
        if removeAppButton.waitForExistence(timeout: timeout) {
            removeAppButton.tap()
        } else {
            XCTFail("Failed to find 'Remove App'")
        }

        let deleteAppButton = springboard.alerts.buttons["Delete App"]
        if deleteAppButton.waitForExistence(timeout: timeout) {
            deleteAppButton.tap()
        } else {
            XCTFail("Failed to find 'Delete App'")
        }

        let finalDeleteButton = springboard.alerts.buttons["Delete"]
        if finalDeleteButton.waitForExistence(timeout: timeout) {
            finalDeleteButton.tap()
        } else {
            XCTFail("Failed to find 'Delete'")
        }
    }
}
