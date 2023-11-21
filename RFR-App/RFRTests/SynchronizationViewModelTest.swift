//
//  SynchronizationViewModelTest.swift
//  RFRTests
//
//  Created by Klemens Muthmann on 30.10.23.
//

import XCTest
@testable import DataCapturing
@testable import Ready_for_Robots_Development

final class SynchronizationViewModelTest: XCTestCase {

    func test() async throws {
        // Arrange
        let mockAuthenticator = MockAuthenticator()
        let testEndpoint = URL(string: "http://localhost:8080/api")!
        let sessionRegistry = SessionRegistry()
        let mockPersistenceLayer = MockPersistenceLayer(
            measurements: [
                FinishedMeasurement(identifier: 0, synchronizable: true),
                FinishedMeasurement(identifier: 1, synchronizable: true)
            ]
        )
        let dataStoreStack = MockDataStoreStack(persistenceLayer: mockPersistenceLayer)

        let oocut = SynchronizationViewModel(
            authenticator: mockAuthenticator, 
            dataStoreStack: dataStoreStack,
            uploadProcessBuilder: MockUploadProcessBuilder(
                apiEndpoint: testEndpoint,
                sessionRegistry: sessionRegistry
            )
        )

        // Collect all the status updates via Combine
        var statii = [UploadStatus]()
        let sinkCancellable = oocut.uploadStatusPublisher.sink { status in
            statii.append(status)
        }

        // Act
        await oocut.synchronize()

        // Assert
        XCTAssertEqual(statii.count, 4)
        statii.forEach { status in
            if case UploadStatusType.finishedWithError = status.status {
                XCTFail()
            }
        }
    }
}

class MockUploadProcessBuilder: UploadProcessBuilder {

    let apiEndpoint: URL
    let sessionRegistry: SessionRegistry

    init(apiEndpoint: URL, sessionRegistry: SessionRegistry) {
        self.apiEndpoint = apiEndpoint
        self.sessionRegistry = sessionRegistry
    }

    func build() -> DataCapturing.UploadProcess {
        return MockUploadProcess()
    }
}

class MockUploadProcess: UploadProcess {
    func upload(authToken: String, _ upload: DataCapturing.Upload) async throws -> DataCapturing.Upload {
        return upload
    }
}
