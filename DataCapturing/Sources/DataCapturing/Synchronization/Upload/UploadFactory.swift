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

 Implementations of this protocol are used by an ``UploadProcess`` to create new uploads.
 Using such a factory is especially useful for testing, as it allows to mock the createion process for an `Upload`. avoiding actual interaction with a data storage layer.
 On the other hand it can be used to provide different implementations for different storage layers.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
public protocol UploadFactory {
    /// Create the requested ``Upload`` from the provided ``FinishedMeasurement``.
    func upload(for measurement: FinishedMeasurement) -> any Upload
    /// Create a new upload based on the provided stored ``UploadSession``.
    /// This method should only be called from within a valid CoreData context.
    /// If not called from within such a context errors will probably start to occur randomly in the vicinity of calls to this method.
    func upload(for session: UploadSession) throws -> any Upload
}

/**
 Create ``CoreDataBackedUpload`` instances.

 Such instances may be created for measurements that have no active session via ``CoreDataBackedUploadFactory/upload(for:)-2qf4d`` or for already stored sessions via ``CoreDataBackedUploadFactory/upload(for:)-f2kk``.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
public struct CoreDataBackedUploadFactory: UploadFactory {
    // MARK: - Properties
    /// A ``DataStoreStack`` to load and store data for the created ``CoreDataBackedUpload`` instances
    let dataStoreStack: DataStoreStack

    // MARK: - Initializers
    /// Create a new instance of this class, creating an ``Upload`` that stores and loads data via the provided `coreDataStack`.
    public init(dataStoreStack: DataStoreStack) {
        self.dataStoreStack = dataStoreStack
    }

    // MARK: - Methods
    public func upload(for measurement: FinishedMeasurement) -> any Upload {
        return CoreDataBackedUpload(dataStoreStack: dataStoreStack, measurement: measurement)
    }

    public func upload(for session: UploadSession) throws -> any Upload {
        guard let measurement = session.measurement else {
            throw PersistenceError.inconsistentState
        }
        let finishedMeasurement = try FinishedMeasurement(managedObject: measurement)
        return CoreDataBackedUpload(dataStoreStack: dataStoreStack, measurement: finishedMeasurement)
    }
}
