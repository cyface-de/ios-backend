/*
 * Copyright 2022 Cyface GmbH
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
import ViewInspector
@testable import Cyface_App
import SwiftUI

class Cyface_AppTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    /// Since we need an external framework to verify our UI, this test makes sure, that this framework is installed correctly. All further errors are our own fault.
    func testViewInspectorBaseline() {
        let expected = "It lives!"
        let sut = Text(expected)
        let value = try? sut.inspect().text().string()
        XCTAssertEqual(value, expected)
    }

    func testLoginScreen() throws {
        let vut = LoginView(settings: PreviewSettings())
        /*let expectation = vut.inspection.inspect { view in
            let loginButton = try vut.inspect().find(button: "Login")
            XCTAssertTrue(try loginButton.buttonStyle() is CyfaceButton)
        }*/

        //self.wait(for: [expectation], timeout: 10.0)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testDisplaysErrorOnWrongCredentials() {}
    func testDisplaysErrorOnMissingConnection() {}
    func testSuccessfulOnCorrectLogin() {}
    func testShowsRegistrationOnClickOnRegistration() {}

}
