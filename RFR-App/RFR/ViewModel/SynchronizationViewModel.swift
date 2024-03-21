/*
 * Copyright 2023-2024 Cyface GmbH
 *
 * This file is part of the Ready for Robots App.
 *
 * The Ready for Robots App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Ready for Robots App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Ready for Robots App. If not, see <http://www.gnu.org/licenses/>.
 */
import Foundation
import DataCapturing
import OSLog
import Combine
import UIKit
import Sentry

/**
 View Model used as an interface to synchronize measurements and keep the UI up to date about synchronization progress.

 - Author: Klemens Muthmann
 - Version: 1.0.1
 - Since: 3.1.2
 */
class SynchronizationViewModel: NSObject, ObservableObject {
    /// Showing an error dialog if not `nil`.
    @Published var error: Error?
    /// A publisher about changes to the ``UploadStatus`` of the currently synchronizing measurements.
    let uploadStatusPublisher: PassthroughSubject<UploadStatus, Never>
    /// The data store stack used to access data storage to read measurements from.
    let dataStoreStack: DataStoreStack
    /// Used to get a proper authentication token for uploading data to the server.
    let authenticator: Authenticator
    /// A builder responsible for creating new ``UploadProcess`` instances on each new upload.
    let processBuilder: UploadProcessBuilder
    /// Store the reporting of ``UploadStatus``events here, so the ``UploadProcess`` keeps reporting.
    var uploadStatusCancellable: AnyCancellable?

    /// Create a new completely initialized object of this class.
    /// Nothing surprising is happening here.
    /// All the properties are initialized with the provided values `nil` or a default value if possible.
    init(authenticator: Authenticator, dataStoreStack: DataStoreStack, uploadProcessBuilder: UploadProcessBuilder) {
        self.dataStoreStack = dataStoreStack
        self.uploadStatusPublisher = PassthroughSubject<UploadStatus, Never>()
        self.error = nil
        self.authenticator = authenticator
        self.processBuilder = uploadProcessBuilder
    }

    /// Start synchronization for all local but not yet synchronized measurements.
    func synchronize() async {
        // TODO: Run this on a background thread
        var uploadProcess = processBuilder.build()
        self.uploadStatusCancellable = uploadProcess.uploadStatus.sink { [weak self] status in
            self?.uploadStatusPublisher.send(UploadStatus(measurement: status.upload.measurement, status: status.status))
        }
        do {
            let measurements = try dataStoreStack.wrapInContextReturn { context in
                let request = MeasurementMO.fetchRequest()
                request.predicate = NSPredicate(format: "synchronizable=%@ AND synchronized=%@", NSNumber(booleanLiteral: true), NSNumber(booleanLiteral: false))
                return try request.execute().map { try FinishedMeasurement(managedObject: $0)}
            }
            os_log("Sync: Synchronizing %d measurements!", log: OSLog.synchronization, type: .debug, measurements.count)
            for measurement in measurements {
                os_log(.debug, log: OSLog.synchronization, "Sync: Starting synchronization of measurement %d!", measurement.identifier)
                do {
                    let authToken = try await authenticator.authenticate()
                    _ = try await uploadProcess.upload(measurement: measurement, authToken: authToken)
                    os_log(.debug, log: OSLog.synchronization, "Sync: Run synchronization of measurement %d!", measurement.identifier)
                } catch {
                    SentrySDK.capture(error: error)
                    os_log(.error, log: OSLog.synchronization, "Sync: Failed synchronizing measurement %d!", measurement.identifier)
                    os_log("Sync: Synchronization failed due to: %@", log: OSLog.synchronization, type: .error, error.localizedDescription)
                    uploadStatusPublisher.send(UploadStatus(measurement: measurement, status: .finishedWithError(cause: error)))
                }
            }
        } catch {
            SentrySDK.capture(error: error)
            self.error = error
        }
    }
}

/**
A wrapper for grouping a ``FinishedMeasurement`` together with its current ``UploadStatusType``.

 - Author: Klemens Muthmann
 - Version 1.0.0
 */
struct UploadStatus {
    /// The measurement the status belongs to.
    let measurement: FinishedMeasurement
    /// The status of the measurement.
    let status: UploadStatusType
}
