/*
 * Copyright 2024 Cyface GmbH
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

import Combine

/**
 An ``UploadProcess`` used for testing or SwiftUI previews.

 This upload process does nothing. It sends no status updates and calls no network code.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
class MockUploadProcess: UploadProcess {
    // MARK: - Properties
    /// An implementation of the `uploadStatus` that never sends any updates.
    var uploadStatus = PassthroughSubject<DataCapturing.UploadStatus, Never>()

    // MARK: - Methods
    /// This upload method simply returns a ``MockUpload`` for the provided ``FinishedMeasurement``, without ever calling any network code.
    func upload(measurement: DataCapturing.FinishedMeasurement) async throws -> any DataCapturing.Upload {
        return MockUpload(measurement: measurement)
    }
}
