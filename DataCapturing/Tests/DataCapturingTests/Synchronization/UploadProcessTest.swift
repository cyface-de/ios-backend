
/*
 * Copyright 2022-2024 Cyface GmbH
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
import Mocker
@testable import DataCapturing

/**
A complete integration test for the whole process of uploading a `Measurement` to a Cyface server. All tests are mocking the network calls by either using the *Mocker* library or a custom `URLProtocol`.

 - author: Klemens Muthmann
 - version: 1.0.1
 */
class UploadProcessTest: XCTestCase {

    /// An example for a URL hosting a Cyface API endpoint.
    private let apiURL = "http://localhost:8080/api/v3/"
    /// An example for a URL providing the endpoint to upload measurements to.
    private let measurementsURL = "http://localhost:8080/api/v3/measurements"
    /// An example for a URL for a single measurement.
    private let uploadURL = "http://localhost:8080/api/v3/measurements/(4e8508e5d5798049dc40fed3d87c7cde)/"

    /// This test carries out a happy path upload process. It uses the *Mocker* framework to avoid actual network requests.
    func testUpload_HappyPath() async throws {
        // Arrange
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockingURLProtocol.self] + (configuration.protocolClasses ?? [])
        let mockedSession = URLSession(configuration: configuration)

        let apiURL = try XCTUnwrap(URL(string: apiURL))
        let measurementsURL = try XCTUnwrap(URL(string: measurementsURL))
        let uploadURL = try XCTUnwrap(URL(string: uploadURL))

        let mockedMeasurementsRequest = Mock(url:measurementsURL, dataType: .json, statusCode: 200, data: [.post: Data()], additionalHeaders: ["Location": self.uploadURL])
        mockedMeasurementsRequest.register()
        let mockedUploadURLRequest = Mock(url: uploadURL, dataType: .json, statusCode: 201, data: [.put: Data()])
        mockedUploadURLRequest.register()

        let sessionRegistry = DefaultSessionRegistry()

        var oocut = DefaultUploadProcess(openSessions: sessionRegistry, apiUrl: apiURL, urlSession: mockedSession, uploadFactory: MockUploadFactory())

        let mockMeasurement = FinishedMeasurement(identifier: 1)

        // Act
        let result = try await oocut.upload(measurement: mockMeasurement, authToken: "mock-token")


        // Assert
        XCTAssertEqual(result.failedUploadsCounter, 0)
        XCTAssertEqual(result.measurement.identifier, 1)
        XCTAssertTrue(result is MockUpload)
        XCTAssertEqual((result as! MockUpload).wasSuccessful, true)
    }

    /// This test checks if the upload process repeats after a failed upload attempt. It uses a custom URLProtocol to avoid actual network calls. This is necessary since *Mocker* does not support changing the response to a request during tests.
    func testUpload_Repeat() async throws {
        // Arrange
        let apiURL = try XCTUnwrap(URL(string: apiURL))
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [URLProtocolStub.self]  + (configuration.protocolClasses ?? [])
        let mockedSession = URLSession(configuration: configuration)
        let mockMeasurement = FinishedMeasurement(identifier: 1)
        let sessionRegistry = DefaultSessionRegistry()
        // Mock Auth Response
        URLProtocolStub.loadingHandler.append({(request: URLRequest) in (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Authorization": "abcdefg"])!,Data())})
        // Mock PreRequest
        URLProtocolStub.loadingHandler.append({(request: URLRequest) in (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Location": "\(apiURL)(1234567890)"])!, Data())})
        // Mock Failed Upload
        URLProtocolStub.loadingHandler.append({(request: URLRequest) in (HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: "HTTP/1.1", headerFields: [String: String]())!, Data())})
        // Mock Status Request
        URLProtocolStub.loadingHandler.append({(request: URLRequest) in (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [String: String]())!, Data())})
        // Mock Successful Upload
        URLProtocolStub.loadingHandler.append({(request: URLRequest) in (HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: "HTTP/1.1", headerFields: [String: String]())!, Data())})

        var uploadProcess = DefaultUploadProcess(openSessions: sessionRegistry, apiUrl: apiURL, urlSession: mockedSession, uploadFactory: MockUploadFactory())

        // Act
        let result = try await uploadProcess.upload(measurement: mockMeasurement, authToken: "mock-token")

        // Assert
        XCTAssertTrue(result is MockUpload)
        let mockResult = result as! MockUpload
        XCTAssertEqual(mockResult.failedUploadsCounter, 1)
        XCTAssertEqual(mockResult.wasSuccessful, false)
    }
}

/**
A mocked upload that does not get data from a CoreData store or something similar but just provides the same hardcoded data on each invocation.

 The test data provided via this upload is randomly generated. The numbers have no meaning.

 - author: Klemens Muthmann
 - version: 2.1.0
 */
class MockUpload: Upload {

    static func == (lhs: MockUpload, rhs: MockUpload) -> Bool {
        return lhs.measurement == rhs.measurement
        }
    
    /// The measurement to upload.
    var measurement: FinishedMeasurement

    /// The counter for this uploads failures.
    var failedUploadsCounter: Int = 0

    /// Check this to see whether `onSuccess` has been called
    var wasSuccessful = false

    /// An optionally empty location to store the upload at.
    var location: URL?

    /// Initialize this class with a simulated measurement identifier.
    init(measurement: FinishedMeasurement) {
        self.measurement = measurement
    }

    // MARK: - Methods

    /// Provide non sense test meta data about this upload.
    func metaData() throws -> MetaData {
        let ret = MetaData(
            locationCount: 3,
            formatVersion: 2,
            startLocLat: 1.0,
            startLocLon: 1.0,
            startLocTS: Date(timeIntervalSince1970: 10_000),
            endLocLat: 1.0,
            endLocLon: 1.0,
            endLocTS: Date(timeIntervalSince1970: 10_100),
            measurementId: 1,
            osVersion: "ios12",
            applicationVersion: "10.0.0",
            length: 10.0,
            modality: "BICYCLE"
        )
        return ret
    }

    /// Some random test data to upload.
    func data() -> Data {
        let bundle = Bundle.module
        guard let path = bundle.path(forResource: "serializedFixture", ofType: "cyf") else {
            fatalError()
        }

        guard let ret = FileManager.default.contents(atPath: path) else {
            fatalError()
        }

        return ret
    }

    func onSuccess() throws {
        wasSuccessful = true
    }
}

struct MockUploadFactory: UploadFactory {
    func upload(for measurement: DataCapturing.FinishedMeasurement) -> any DataCapturing.Upload {
        return MockUpload(measurement: measurement)
    }
    
    func upload(for session: DataCapturing.UploadSession) throws -> any DataCapturing.Upload {
        guard let measurement = session.measurement else {
            throw PersistenceError.inconsistentState
        }
        return MockUpload(measurement: try FinishedMeasurement(managedObject: measurement))
    }
}

/**
A `URLProtocol` implementation that catches request before hitting the actual network and providing a hand crafted response based on a list of possible responses.

 The list of responses is traversed one by one. That way the expected responses can be registered before starting the test. The test then can show whether it reacts appropriately.

 - author: Klemens Muthmann
 - version: 1.0.0
 */
public class URLProtocolStub: URLProtocol {

    /// The current `loadingHandler` to use to answer the request.
    static var step = 0
    /// A list of closure to create responses.
    static var loadingHandler = [((URLRequest) throws -> (HTTPURLResponse, Data))]()

    public override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    public override func startLoading() {
        guard Self.step<Self.loadingHandler.count else {
            XCTFail("Loading handler is not set on request to \(String(describing: request.url))")
            return
        }
        let handler = Self.loadingHandler[Self.step]
        Self.step += 1
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    public override func stopLoading() { }
}
