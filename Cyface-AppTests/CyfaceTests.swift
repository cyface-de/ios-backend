//
//  Cyface_AppTests.swift
//  Cyface-AppTests
//
//  Created by Klemens Muthmann on 25.03.22.
//

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
        let vut = LoginView(credentials: Credentials(username: "ali", password: "test"))
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
