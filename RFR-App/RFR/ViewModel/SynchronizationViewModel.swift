//
//  SynchronizationViewModel.swift
//  RFR
//
//  Created by Klemens Muthmann on 12.04.23.
//

import Foundation
import DataCapturing
import OSLog
import Combine

class SynchronizationViewModel: ObservableObject {
    @Published var error: Error?
    let uploadStatusPublisher: PassthroughSubject<UploadStatus, Never>
    let dataStoreStack: DataStoreStack
    let apiEndpoint: URL
    let sessionRegistry: SessionRegistry
    // TODO: Inject this.
    let authenticator = OAuthAuthenticator()

    init(dataStoreStack: DataStoreStack, apiEndpoint: URL, sessionRegistry: SessionRegistry) {
        self.dataStoreStack = dataStoreStack
        self.uploadStatusPublisher = PassthroughSubject<UploadStatus, Never>()
        self.error = nil
        self.apiEndpoint = apiEndpoint
        self.sessionRegistry = sessionRegistry

        //self.synchronizer.handler.append(handle)
        /*do {
            try synchronizer.activate()
        } catch {
            self.error = error
        }*/
    }

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
                    let result = try await uploadProcess.upload(authToken: authToken, upload)
                    uploadStatusPublisher.send(UploadStatus(id: measurement.identifier, status: .finishedSuccessfully))
                } catch {
                    uploadStatusPublisher.send(UploadStatus(id: measurement.identifier, status: .finishedWithError(cause: error)))
                }
            }
        } catch {
            self.error = error
        }
    }

    /*func deactivate() {
        synchronizer.deactivate()
    }

    func handle(syncEvent: DataCapturingEvent, status: Status) {
        switch status {
        case .success:
            switch syncEvent {
            case .synchronizationStarted(measurement: let measurement):
                uploadStatusPublisher.send(UploadStatus(id: measurement.identifier, status: .started))
            case .synchronizationFinished(measurement: let measurement):
                // TODO: This needs to provide error information if the upload was not successful. --> Error information should be part of status field
                uploadStatusPublisher.send(UploadStatus(id: measurement.identifier, status: .finished))
            default:
                os_log("Unhandled synchronization event %@", log: OSLog.synchronization, type: .debug, syncEvent.description)
            }
        case .error(let error):
            self.error = error
        }
    }*/

    /*deinit {
        synchronizer.deactivate()
    }*/
}

struct UploadStatus {
    let id: UInt64
    let status: UploadStatusType
}

enum UploadStatusType {
    case started
    case finishedSuccessfully
    case finishedWithError(cause: Error)
}
