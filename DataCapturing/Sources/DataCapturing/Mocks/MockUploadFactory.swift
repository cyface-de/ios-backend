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

import Foundation

public struct MockUploadFactory: UploadFactory {
    public init() {
        // Nothing to do here.
    }

    public func upload(for measurement: DataCapturing.FinishedMeasurement) -> any DataCapturing.Upload {
        return MockUpload(measurement: measurement)
    }

    public func upload(for session: DataCapturing.UploadSession) throws -> any DataCapturing.Upload {
        guard let measurement = session.measurement else {
            throw PersistenceError.inconsistentState
        }
        return MockUpload(measurement: try FinishedMeasurement(managedObject: measurement))
    }
}
