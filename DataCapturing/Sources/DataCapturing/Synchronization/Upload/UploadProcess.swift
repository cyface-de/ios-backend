/*
 * Copyright 2023 Cyface GmbH
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

import Foundation
import OSLog

public protocol UploadProcess {
    /// Start the upload process for the provided `Upload`.
    /// Called after authentication with the Cyface data collector service was successful.
    /// - returns: The successful upload
    func upload(authToken: String, _ upload: Upload) async throws -> Upload
}

// TODO: Repeat Request after Authentication has failed
/**
 A state machine for the complete upload process of a single measurement from this device to a Cyface Data Collector service.

 It orchestrates the different requests required by the Cyface Upload Protocol.

 - author: Klemens Muthmann
 - version: 1.0.0
 */
public class DefaultUploadProcess: UploadProcess {
    /// Session registry storing sessions open for resume.
    var openSessions: SessionRegistry
    /// The URL to the Cyface data collector.
    let apiUrl: URL
    /// A `URLSession` to use for sending requests and receiving responses, probably in the background.
    lazy var discretionaryUrlSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: discretionaryUrlSessionIdentifier)
        //Determines the maximum number of simulataneous connections to a Host. This is a per session property.
        config.httpMaximumConnectionsPerHost = 1
        // This controles whether you are allowed to continue your upload/download over cellular access.
        config.allowsCellularAccess = false
        // This makes sure you get an event on your app session launch (in your AppDelegate). (Your app might be killed by system even if your upload/download is going on)
        config.sessionSendsLaunchEvents = true
        // This tells the system to wait for connectivity and then resume uploading/downloading. If the network goes away, it will restart from 0.
        // This is ignored by background sessions always waiting for connectivity
        config.waitsForConnectivity = true
        // Only transmit during convenient times
        config.isDiscretionary = true

        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    var backgroundSessionCompletionHandler: (() -> Void)?
    let discretionaryUrlSessionIdentifier = "de.cyface.urlsession.discretionary"

    /// Makes a new `UploadProcess` using the supplied properties.
    ///
    /// - Parameter apiUrl: The root URL for the Cyface API.
    /// - Parameter sessionRegistry: You may reuse some `SessionRegistry` here or provide one backed by persistent storage. If the sessions are not stored somewhere nothing bad will happen, except from a few unecessary uploads, which could have been resumed.
    public init(apiUrl: URL, session: URLSession = URLSession.shared, sessionRegistry: SessionRegistry) {
        self.openSessions = sessionRegistry
        self.apiUrl = apiUrl
    }

    public func upload(authToken: String, _ upload: Upload) async throws -> Upload {
        if let currentSession = openSessions.session(for: upload) {
            let statusRequest = StatusRequest(apiUrl: apiUrl, session: discretionaryUrlSession, authToken: authToken)

            let response = try await statusRequest.request(
                sessionIdentifier: currentSession,
                upload: upload
            )

            switch response {
            case .finished:
                try upload.onSuccess()
                return upload
            case .resume:
                return try await onSuccessfulStatusRequest(authToken: authToken, sessionIdentifier: currentSession, upload: upload)
            case .aborted:
                return try await onAbortedStatusRequest(authToken: authToken, upload: upload)
            }
        } else {
            let preRequest = PreRequest(apiUrl: apiUrl, session: discretionaryUrlSession)

            let response = try await preRequest.request(authToken: authToken, upload: upload)

            switch response {
            case .success(location: let location):
                let finishedUpload = try await onSuccessfulPreRequest(authToken: authToken, sessionIdentifier: location, upload: upload)
                try finishedUpload.onSuccess()
                return finishedUpload
            case .exists:
                try upload.onSuccess()
                return upload
            }
        }
    }

    /// Called after a status request on an open session returned successfully.
    private func onSuccessfulStatusRequest(authToken: String, sessionIdentifier: String, upload: Upload) async throws -> Upload {
        let uploadRequest = UploadRequest(session: discretionaryUrlSession)

        do {
            return try await uploadRequest.request(
                authToken: authToken,
                sessionIdentifier: sessionIdentifier,
                upload: upload
            )
        } catch {
            return try await onFailedUploadRequest(authToken: authToken, sessionIdentifier: sessionIdentifier, upload: upload, error: error)
        }
    }

    /// Called if a status request was aborted by the server.
    private func onAbortedStatusRequest(authToken: String, upload: Upload) async throws -> Upload {
        let preRequest = PreRequest(apiUrl: apiUrl, session: discretionaryUrlSession)

        let response = try await preRequest.request(authToken: authToken, upload: upload)

        switch response {
        case .success(location: let location):
            return try await onSuccessfulPreRequest(authToken: authToken, sessionIdentifier: location, upload: upload)
        case .exists:
            return upload
        }
    }

    /// Called if an upload pre request was successful.
    private func onSuccessfulPreRequest(authToken: String, sessionIdentifier: String, upload: Upload) async throws -> Upload {
        let uploadRequest = UploadRequest(session: discretionaryUrlSession)
        openSessions.register(session: sessionIdentifier, upload: upload)

        do {
            return try await uploadRequest.request(
                authToken: authToken,
                sessionIdentifier: sessionIdentifier,
                upload: upload)
        } catch {
            return try await onFailedUploadRequest(authToken: authToken, sessionIdentifier: sessionIdentifier, upload: upload, error: error)
        }

    }

    /// Called after a failed upload request.
    private func onFailedUploadRequest(authToken: String, sessionIdentifier: String, upload: Upload, error: Error) async throws -> Upload {
        var upload = upload
        upload.failedUploadsCounter += 1

        if upload.failedUploadsCounter > 3 {
            upload.failedUploadsCounter = 0
            throw error
        } else {
            let statusRequest = StatusRequest(apiUrl: apiUrl, session: discretionaryUrlSession, authToken: authToken)

            let response = try await statusRequest.request(
                sessionIdentifier: sessionIdentifier,
                upload: upload
            )

            switch response {
            case .finished:
                return upload
            case .resume:
                return try await onSuccessfulPreRequest(authToken: authToken, sessionIdentifier: sessionIdentifier, upload: upload)
            case .aborted:
                return try await onAbortedStatusRequest(authToken: authToken, upload: upload)
            }
        }
    }

}

extension UploadProcess: URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        //let taskIndex = find(task: task.taskIdentifier)
        // discretionaryTasks.remove(at: taskIndex)
        // TODO: Im Beispielprojekt testen wie ich an Objekte komme, die zuletzt im Speicher waren. Muss ich die in einer
        // Datei ablegen oder kann ich sie einfach als Properties behalten. Auf jedenfall brauche ich zum Beispiel das akutelle
        // Upload Objekt an dieser Stelle, um den Upload nach einem StatusRequest oder einem PreRequest fortsetzen zu können.

        guard let response = task.response as? HTTPURLResponse else {
            self.error = ServerConnectionError.noResponse
            return
        }

        if let error = error {
            self.error = error
            return
        }

        // TODO
        //lastUploadStatus = httpResponse.statusCode
        //delegate?.errorInvalid()
    }

    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        os_log("Finished background session", log: OSLog.synchronization, type: .info)
        DispatchQueue.main.async { [weak self] in
            if let completionHandler = self?.backgroundSessionCompletionHandler {
                self?.backgroundSessionCompletionHandler = nil
                completionHandler()
            }
        }
    }
}
