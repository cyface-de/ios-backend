/*
 * Copyright 2023-2024 Cyface GmbH
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
import Combine
@testable import DataCapturing
@testable import Ready_for_Robots_Development

/**
 Tests that the synchronization view model correctly synchronizes measurements and provides the current state of that synchronization.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
final class SynchronizationViewModelTest: XCTestCase {

    func test() async throws {
        // Arrange
        let mockAuthenticator = MockAuthenticator()
        let testEndpoint = URL(string: "http://localhost:8080/api")!
        let sessionRegistry = DefaultSessionRegistry()
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
        var statii = [Ready_for_Robots_Development.UploadStatus]()
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
