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
import Combine

/**
 A ``SessionRegistry`` capable of keeping sessions between application restarts, by storing them to a persistent storage.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
public class PersistentSessionRegistry: SessionRegistry {
    // MARK: - Properties
    let dataStoreStack: DataStoreStack
    let uploadFactory: UploadFactory
    let uploadStatus = PassthroughSubject<UploadStatus, Never>()

    // MARK: - Initializers
    public init(dataStoreStack: DataStoreStack, uploadFactory: UploadFactory) {
        self.dataStoreStack = dataStoreStack
        self.uploadFactory = uploadFactory
    }

    // MARK: - Methods
    public func get(measurement: FinishedMeasurement) throws -> (any Upload)? {
        return try dataStoreStack.wrapInContextReturn { context in
            return try uploadFromCoreData(measurement: measurement)
        }
    }

    public func register(upload: any Upload) throws {
        try dataStoreStack.wrapInContext { context in
            let uploadSession = UploadSession(context: context)
            uploadSession.location = upload.location
            uploadSession.time = Date()
            uploadSession.measurement = try measurementFromCoreData(upload.measurement.identifier, context)

            try context.save()
        }
        uploadStatus.send(UploadStatus(upload: upload, status: .started))
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

            try context.save()
        }

        if case requestType = .upload, httpStatusCode == 201 {
            uploadStatus.send(UploadStatus(upload: upload, status: .finishedSuccessfully))
            try upload.onSuccess()
        }
    }

    public func record(upload: any Upload, _ requestType: RequestType, httpStatusCode: Int16, error: Error) throws {
        try dataStoreStack.wrapInContext { context in
            let request = UploadSession.fetchRequest()
            request.predicate = NSPredicate(format: "measurement.identifier=%d", upload.measurement.identifier)
            request.fetchLimit = 1
            guard let uploadSession = try request.execute().first else {
                throw PersistenceError.sessionNotRegistered(upload.measurement)
            }

            let protocolEntry = UploadTask(context: context)
            protocolEntry.causedError = true
            protocolEntry.command = requestType.rawValue
            protocolEntry.httpStatus = httpStatusCode
            protocolEntry.message = error.localizedDescription
            protocolEntry.time = Date.now
            uploadSession.addToUploadProtocol(protocolEntry)

            try context.save()
        }
        uploadStatus.send(UploadStatus(upload: upload, status: .finishedWithError(cause: error)))
    }

    public func remove(upload: any Upload) throws {
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

/**
 A mapping between an ``Upload`` and and its current upload status.

 - Author: Klemens Muthmann
 - Version: 2.0.0
 - Since: 3.1.2
 */
struct UploadStatus {
    /// The measurement identifier of this status.
    let upload: any Upload
    /// The current status.
    let status: UploadStatusType
}

/**
 The current status of an upload to a Cyface Data Collector service.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.2
 */
enum UploadStatusType: CustomStringConvertible {
    /// Upload has been started
    case started
    /// Upload was finished successfully.
    case finishedSuccessfully
    /// Upload failed because of the provided error.
    case finishedWithError(cause: Error)

    var description: String {
        switch(self) {
        case .started:
            "started"
        case .finishedSuccessfully:
            "finishedSuccessfully"
        case .finishedWithError(cause: let error):
            "finishedWithError: \(error.localizedDescription)"
        }
    }
}
