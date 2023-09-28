/*
 * Copyright 2023 Cyface GmbH
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
 - Version: 1.0.0
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
        let uploadProcess = processBuilder.build()
        do {
            let measurements = try dataStoreStack.persistenceLayer().loadSynchronizableMeasurements()
            os_log("Synchronizing %d measurements!", log: OSLog.synchronization, type: .debug, measurements.count)
            for measurement in measurements {
                os_log(.debug, log: OSLog.synchronization, "Starting synchronization of measurement %d!", measurement.identifier)
                uploadStatusPublisher.send(UploadStatus(id: measurement.identifier, status: .started))
                do {
                    let upload = CoreDataBackedUpload(dataStoreStack: dataStoreStack, measurement: measurement)
                    let authToken = try await authenticator.authenticate()
                    _ = try await uploadProcess.upload(authToken: authToken, upload)
                    os_log(.debug, log: OSLog.synchronization, "Successfully finished synchronization of measurement %d!", measurement.identifier)
                    uploadStatusPublisher.send(UploadStatus(id: measurement.identifier, status: .finishedSuccessfully))
                } catch {
                    SentrySDK.capture(error: error)
                    os_log(.error, log: OSLog.synchronization, "Failed synchronizing measurement %d!", measurement.identifier)
                    if let defaultUploadProcessBuilder = processBuilder as? DefaultUploadProcessBuilder {
                        os_log(.error, log: OSLog.synchronization, "Data Collector API Address: %@", defaultUploadProcessBuilder.apiEndpoint.absoluteString)
                    }
                    if let oAuthAuthenticator = authenticator as? OAuthAuthenticator {
                        os_log(.error, log: OSLog.authorization, "Identity Provider Address: %@", oAuthAuthenticator.issuer.absoluteString)
                    }
                    os_log("Synchronization failed due to: %@", log: OSLog.synchronization, type: .error, error.localizedDescription)
                    uploadStatusPublisher.send(UploadStatus(id: measurement.identifier, status: .finishedWithError(cause: error)))
                }
            }
        } catch {
            SentrySDK.capture(error: error)
            self.error = error
        }
    }
}

/**
 A mapping between a local measurement identifier and and its current upload status.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.2
 */
struct UploadStatus {
    /// The measurement identifier of this status.
    let id: UInt64
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
