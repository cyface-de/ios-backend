//
//  UploadProcessTest.swift
//  DataCapturing-Unit-Tests
//
//  Created by Klemens Muthmann on 17.03.22.
//

import XCTest
@testable import DataCapturing

class UploadProcessTest: XCTestCase {

    func testHappyPath() {
        // Arrange
        guard let apiUrl = URL(string: "http://localhost/api/v3") else {
            return XCTFail("Fixture contains unvalid URL!")
        }
        let sessionRegistry = SessionRegistry()
        let onSuccess = {(measurementIdentifier: Int64) in }
        let onFailure = {(measurementIdentifier: Int64, error: Error) in }
        let oocut = UploadProcess(apiUrl: apiUrl, sessionRegistry: sessionRegistry, onSuccess: onSuccess, onFailure: onFailure)
        let measurement = Int64(1)

        // Act
        oocut.upload(measurement: measurement)

        // Assert
    }

}
