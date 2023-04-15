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
    var synchronizer: Synchronizer
    @Published var error: Error?
    let uploadStatusPublisher: PassthroughSubject<UploadStatus, Never>

    init(synchronizer: Synchronizer) {
        self.synchronizer = synchronizer
        self.uploadStatusPublisher = PassthroughSubject<UploadStatus, Never>()
        self.error = nil

        self.synchronizer.handler.append(handle)
        do {
            try synchronizer.activate()
        } catch {
            self.error = error
        }
    }

    func synchronize() {
        synchronizer.syncChecked()
    }

    func deactivate() {
        synchronizer.deactivate()
    }

    func handle(syncEvent: DataCapturingEvent, status: Status) {
        switch status {
        case .success:
            switch syncEvent {
            case .synchronizationStarted(measurement: let measurementIdentifier):
                uploadStatusPublisher.send(UploadStatus(id: measurementIdentifier, status: .started))
            case .synchronizationFinished(measurement: let measurementIdentifier):
                // TODO: This needs to provide error information if the upload was not successful.
                uploadStatusPublisher.send(UploadStatus(id: measurementIdentifier, status: .finished))
            default:
                os_log("Unhandled synchronization event %@", log: OSLog.synchronization, type: .debug, syncEvent.description)
            }
        case .error(let error):
            self.error = error
        }
    }

    deinit {
        synchronizer.deactivate()
    }
}

struct UploadStatus {
    let id: Int64
    let status: UploadStatusType
}

enum UploadStatusType {
    case started
    case finished
}
