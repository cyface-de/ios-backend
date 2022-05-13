//
//  UploadProcessTest.swift
//  DataCapturing-Unit-Tests
//
//  Created by Klemens Muthmann on 17.03.22.
//

import XCTest
import Alamofire
@testable import DataCapturing

class UploadProcessTest: XCTestCase {

    func testHappyPath() {
        // Arrange
        guard let apiUrl = URL(string: "http://localhost:8080/api/v3") else {
            return XCTFail("Fixture contains unvalid URL!")
        }
        let sessionRegistry = SessionRegistry()
        let expectation = XCTestExpectation(description: "Wait for synchronization to complete.")
        var transmittedMeasurementIdentifier: UInt64?
        var receivedError: Error?
        let onSuccess = {(measurementIdentifier: UInt64) in
            transmittedMeasurementIdentifier = measurementIdentifier
            expectation.fulfill()
        }
        let onFailure = {(measurementIdentifier: UInt64, error: Error) in
            transmittedMeasurementIdentifier = measurementIdentifier
            receivedError = error
            expectation.fulfill()
        }
        let authenticator = CredentialsAuthenticator(authenticationEndpoint: apiUrl)
        authenticator.username = "admin"
        authenticator.password = "secret"
        let oocut = UploadProcess(apiUrl: apiUrl, sessionRegistry: sessionRegistry, authenticator: authenticator, onSuccess: onSuccess, onFailure: onFailure)

        struct MockUpload: Upload {
            var failedUploadsCounter: Int = 0

            var identifier: UInt64

            func metaData() throws -> MetaData {
                let ret = MetaData(locationCount: 3, formatVersion: 2, startLocLat: 1.0, startLocLon: 1.0, startLocTS: 10_000, endLocLat: 1.0, endLocLon: 1.0, endLocTS: 10_100, measurementId: 1, osVersion: "ios12", applicationVersion: "10.0.0", length: 10.0, modality: "BICYCLE")
                return ret
            }

            // TODO: Woher bekomme ich eine Beispielmessung im Protobuf Format? --> Testfall für Protobuf schreiben
            func data() -> Data {
                let bundle = Bundle(for: UploadProcessTest.self)
                guard let path = bundle.path(forResource: "serializedFixture", ofType: "cyf") else {
                    fatalError()
                }

                guard let ret = FileManager.default.contents(atPath: path) else {
                    fatalError()
                }

                return ret
            }


        }

        let mockedUpload = MockUpload(identifier: 1)

        // Act
        oocut.upload(mockedUpload)

        wait(for: [expectation], timeout: 10.0)

        // Assert
        XCTAssertNotNil(transmittedMeasurementIdentifier)
        XCTAssertNil(receivedError)
        XCTAssertEqual(transmittedMeasurementIdentifier, 1)
    }

}

/*protocol MockedSession {
    func upload(_ data: Data,
                     to convertible: URLConvertible,
                     method: HTTPMethod,
                     headers: HTTPHeaders?,
                     interceptor: RequestInterceptor?,
                     fileManager: FileManager,
                     requestModifier: RequestModifier?) -> UploadRequest
}

extension Session: MockedSession {
    open func upload(_ data: Data,
                     to convertible: URLConvertible,
                     method: HTTPMethod = .post,
                     headers: HTTPHeaders? = nil,
                     interceptor: RequestInterceptor? = nil,
                     fileManager: FileManager = .default,
                     requestModifier: RequestModifier? = nil) -> Alamofire.UploadRequest {
        return Alamofire.UploadRequest(apiUrl: "", session: self)
    }
}*/
