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
import CoreData

/**
 A ``SessionRegistry`` capable of keeping sessions between application restarts, by storing them to a persistent storage.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
public struct PersistentSessionRegistry: SessionRegistry {
    // MARK: - Properties
    let dataStoreStack: DataStoreStack
    let uploadFactory: UploadFactory

    // MARK: - Initializers
    public init(dataStoreStack: DataStoreStack, uploadFactory: UploadFactory) {
        self.dataStoreStack = dataStoreStack
        self.uploadFactory = uploadFactory
    }

    // MARK: - Methods
    public mutating func get(measurement: FinishedMeasurement) throws -> (any Upload)? {
        return try dataStoreStack.wrapInContextReturn { context in
            return try uploadFromCoreData(measurement: measurement)
        }
    }

    public mutating func register(upload: any Upload) throws {
        try dataStoreStack.wrapInContext { context in
            let uploadSession = UploadSession(context: context)
            uploadSession.location = upload.location
            uploadSession.time = Date()
            uploadSession.measurement = try measurementFromCoreData(upload.measurement.identifier, context)

            try context.save()
        }
    }

    public func record(upload: any Upload, _ requestType: RequestType, httpStatusCode: Int16, message: String, time: Date) throws {
        try dataStoreStack.wrapInContext { context in
            let request = UploadSession.fetchRequest()
            request.predicate = NSPredicate(format: "measurement.identifier=%d", upload.measurement.identifier)
            request.fetchLimit = 1
            guard let uploadSession = try request.execute().first else {
                throw PersistenceError.sessionNotRegistered(upload.measurement)
            }

            let uploadTask = UploadTask(context: context)
            uploadTask.command = requestType.rawValue
            uploadTask.httpStatus = httpStatusCode
            uploadTask.message = message
            uploadTask.time = time
            uploadSession.addToUploadProtocol(uploadTask)
        }
    }

    public mutating func remove(upload: any Upload) throws {
        try dataStoreStack.wrapInContext { context in
            let request = UploadSession.fetchRequest()
            request.predicate = NSPredicate(format: "measurement.identifier=%d", upload.measurement.identifier)
            request.fetchLimit = 1
            guard let session = try request.execute().first else {
                throw PersistenceError.sessionNotRegistered(upload.measurement)
            }

            context.delete(session)
        }
    }

    private func uploadFromCoreData(measurement: FinishedMeasurement) throws -> (any Upload)? {
        let request = UploadSession.fetchRequest()
        request.predicate = NSPredicate(format: "measurement.identifier=%d", measurement.identifier)
        request.fetchLimit = 1
        if let session = try request.execute().first {
            return try uploadFactory.upload(for: session)
        } else {
            return nil
        }
    }

    private func measurementFromCoreData(_ identifier: UInt64, _ context: NSManagedObjectContext) throws -> MeasurementMO {
        let request = MeasurementMO.fetchRequest()
        request.predicate = NSPredicate(format: "identifier=%d", identifier)
        request.fetchLimit = 1
        guard let storedMeasurement = try request.execute().first else {
            throw PersistenceError.measurementNotLoadable(identifier)
        }
        return storedMeasurement
    }
}

public enum RequestType: Int16 {
    case status = 0
    case prerequest = 1
    case upload = 2
}
