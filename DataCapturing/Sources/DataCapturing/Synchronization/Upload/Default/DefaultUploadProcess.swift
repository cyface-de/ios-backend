//
//  File.swift
//  
//
//  Created by Klemens Muthmann on 27.02.24.
//

import Foundation

// TODO: Repeat Request after Authentication has failed
/**
 A state machine for the complete upload process of a single measurement from this device to a Cyface Data Collector service.

 It orchestrates the different requests required by the Cyface Upload Protocol.

 - author: Klemens Muthmann
 - version: 1.0.0
 */
public struct DefaultUploadProcess {
    // MARK: - Properties
    /// Session registry storing sessions open for resume.
    var openSessions: SessionRegistry
    /// The URL to the Cyface data collector.
    let apiUrl: URL
    /// A `URLSession` to use for sending requests and receiving responses, probably in the background.
    var urlSession = URLSession.shared
    let uploadFactory: UploadFactory
    // MARK: - Static Properties
    public static let discretionaryUrlSessionIdentifier = "de.cyface.urlsession.discretionary"

    // MARK: - Methods
    /// Called after a status request on an open session returned successfully.
    private func onSuccessfulStatusRequest(authToken: String, upload: any Upload) async throws -> any Upload {
        let uploadRequest = UploadRequest(session: urlSession)

        do {
            return try await uploadRequest.request(authToken: authToken, upload: upload)
        } catch {
            return try await onFailedUploadRequest(authToken: authToken, upload: upload, error: error)
        }
    }

    /// Called if a status request was aborted by the server.
    private func onAbortedStatusRequest(authToken: String, upload: any Upload) async throws -> any Upload {
        let preRequest = PreRequest(apiUrl: apiUrl, session: urlSession)

        let response = try await preRequest.request(authToken: authToken, upload: upload)

        switch response {
        case .success(location: let location):
            return try await onSuccessfulPreRequest(authToken: authToken, upload: upload)
        case .exists:
            return upload
        }
    }

    /// Called if an upload pre request was successful.
    private func onSuccessfulPreRequest(authToken: String, upload: any Upload) async throws -> any Upload {
        let uploadRequest = UploadRequest(session: urlSession)

        do {
            return try await uploadRequest.request(authToken: authToken, upload: upload)
        } catch {
            return try await onFailedUploadRequest(authToken: authToken, upload: upload, error: error)
        }

    }

    /// Called after a failed upload request.
    private func onFailedUploadRequest(authToken: String, upload: any Upload, error: Error) async throws -> any Upload {
        var upload = upload
        upload.failedUploadsCounter += 1

        if upload.failedUploadsCounter > 3 {
            upload.failedUploadsCounter = 0
            throw error
        } else {
            let statusRequest = StatusRequest(apiUrl: apiUrl, session: urlSession, authToken: authToken)

            let response = try await statusRequest.request(upload: upload)

            switch response {
            case .finished:
                return upload
            case .resume:
                return try await onSuccessfulPreRequest(authToken: authToken, upload: upload)
            case .aborted:
                return try await onAbortedStatusRequest(authToken: authToken, upload: upload)
            }
        }
    }

    private func handleStatus(response: StatusRequest.Response, _ authToken: String, _ upload: any Upload) async throws -> any Upload {
        switch response {
        case .finished:
            try upload.onSuccess()
            return upload
        case .resume:
            return try await onSuccessfulStatusRequest(authToken: authToken, upload: upload)
        case .aborted:
            return try await onAbortedStatusRequest(authToken: authToken, upload: upload)
        }
    }

    private func handlePreRequest(response: PreRequest.Response, _ authToken: String, _ upload: inout any Upload) async throws -> any Upload {
        switch response {
        case .success(location: let location):
            upload.location = URL(string: location)
            let finishedUpload = try await onSuccessfulPreRequest(authToken: authToken, upload: upload)
            try finishedUpload.onSuccess()
            return finishedUpload
        case .exists:
            try upload.onSuccess()
            return upload
        }
    }
}

// MARK: - Upload Process Implementation
extension DefaultUploadProcess: UploadProcess {

    public mutating func upload(measurement: FinishedMeasurement, authToken: String) async throws -> any Upload {
        if let upload = try openSessions.get(measurement: measurement) {
            let statusRequest = StatusRequest(apiUrl: apiUrl, session: urlSession, authToken: authToken)

            let response = try await statusRequest.request(upload: upload)

            let result = try await handleStatus(response: response, authToken, upload)
            try openSessions.remove(upload: result)
            return result
        } else {
            let preRequest = PreRequest(apiUrl: apiUrl, session: urlSession)
            var upload = uploadFactory.upload(for: measurement)
            try openSessions.register(upload: upload)

            let response = try await preRequest.request(authToken: authToken, upload: upload)

            let result = try await handlePreRequest(response: response, authToken, &upload)
            try openSessions.remove(upload: result)
            return result
        }
    }
}
