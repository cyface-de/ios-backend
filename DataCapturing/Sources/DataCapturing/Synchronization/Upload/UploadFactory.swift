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

/**
 A protocol implemented by factories creating specific ``Upload`` implementations.

 Implementations of this protocl are used by an ``UploadProcess`` to create new uploads from ``FinishedMeasurement`` instance if that `measurement` has no open session.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
public protocol UploadFactory {
    /// Create the requested ``Upload`` from the provided ``FinishedMeasurement``.
    func upload(for measurement: FinishedMeasurement) -> any Upload
}

/**
 Create ``CoreDataBackedUpload`` instances for the provided ``FinishedMeasurement``

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
public struct CoreDataBackedUploadFactory: UploadFactory {
    let dataStoreStack: CoreDataStack

    public init(dataStoreStack: CoreDataStack) {
        self.dataStoreStack = dataStoreStack
    }

    public func upload(for measurement: FinishedMeasurement) -> any Upload {
        return CoreDataBackedUpload(dataStoreStack: dataStoreStack, measurement: measurement)
    }
}
