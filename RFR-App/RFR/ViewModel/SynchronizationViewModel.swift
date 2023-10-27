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

/**
 View Model used as an interface to synchronize measurements and keep the UI up to date about synchronization progress.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
class SynchronizationViewModel: ObservableObject {
    /// Showing an error dialog if not `nil`.
    @Published var error: Error?
    /// A publisher about changes to the ``UploadStatus`` of the currently synchronizing measurements.
    let uploadStatusPublisher: PassthroughSubject<UploadStatus, Never>
    /// The data store stack used to access data storage to read measurements from.
    let dataStoreStack: DataStoreStack
    /// The endpoint of a Cyface Data Collector compatible service to upload data to.
    let apiEndpoint: URL
    /// A registry for running and resumable upload sessions.
    let sessionRegistry: SessionRegistry
    /// Used to get a proper authentication token for uploading data to the server.
    let authenticator: Authenticator

    /// Create a new completely initialized object of this class.
    /// Nothing surprising is happening here.
    /// All the properties are initialized with the provided values `nil` or a default value if possible.
    init(authenticator: Authenticator, dataStoreStack: DataStoreStack, apiEndpoint: URL, sessionRegistry: SessionRegistry) {
        self.dataStoreStack = dataStoreStack
        self.uploadStatusPublisher = PassthroughSubject<UploadStatus, Never>()
        self.error = nil
        self.apiEndpoint = apiEndpoint
        self.sessionRegistry = sessionRegistry
        self.authenticator = authenticator

        //self.synchronizer.handler.append(handle)
        /*do {
            try synchronizer.activate()
        } catch {
            self.error = error
        }*/
    }

    /// Start synchronization for all local but not yet synchronized measurements.
    func synchronize() async {
        // TODO: Run this on a background thread
        let uploadProcess = UploadProcess(apiUrl: apiEndpoint, sessionRegistry: sessionRegistry)
        do {
            let measurements = try dataStoreStack.persistenceLayer().loadSynchronizableMeasurements()
            for measurement in measurements {
                uploadStatusPublisher.send(UploadStatus(id: measurement.identifier, status: .started))
                do {
                    let upload = CoreDataBackedUpload(dataStoreStack: dataStoreStack, measurement: measurement)
                    let authToken = try await authenticator.authenticate()
                    _ = try await uploadProcess.upload(authToken: authToken, upload)
                    uploadStatusPublisher.send(UploadStatus(id: measurement.identifier, status: .finishedSuccessfully))
                } catch {
                    uploadStatusPublisher.send(UploadStatus(id: measurement.identifier, status: .finishedWithError(cause: error)))
                }
            }
        } catch {
            self.error = error
        }
    }
}

/**
 A mapping between a local measurement identifier and and its current upload status.

 - Author: Klemens Muthmann
 - Version: 1.0.0
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
 */
enum UploadStatusType {
    /// Upload has been started
    case started
    /// Upload was finished successfully.
    case finishedSuccessfully
    /// Upload failed because of the provided error.
    case finishedWithError(cause: Error)
}
