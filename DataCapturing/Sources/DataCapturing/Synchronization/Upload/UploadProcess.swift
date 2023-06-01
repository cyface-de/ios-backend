/*
 * Copyright 2022 Cyface GmbH
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
import Alamofire

// TODO: Repeat Request after Authentication has failed
/**
 A state machine for the complete upload process of a single measurement from this device to a Cyface Data Collector service.

 - author: Klemens Muthmann
 - version: 1.0.0
 */
public class UploadProcess {
    /// Session registry storing sessions open for resume.
    var openSessions: SessionRegistry
    /// The URL to the Cyface data collector.
    let apiUrl: URL
    /// Callback called on successful upload.
    let onSuccess: (Upload) -> Void
    /// Callback called on a failed upload.
    let onFailure: (Upload, Error) -> Void
    /// An Alamofire `Session` to use for sending requests and receiving responses.
    let session: Session
    /// Authenticator to get authentication tokens from the upload URL, if the current user is a valid one.
    let authenticator: Authenticator

    /// Makes a new `UploadProcess` using the supplied properties.
    ///
    /// - Parameter session: An optional Alamofire `Session`. Use this to inject a session, for example for mocking. If not used the standard Alamofire `Session` is used, which should be fine for most use cases.
    /// - Parameter sessionRegistry: You may reuse some `SessionRegistry` here or provide one backed by persistent storage. If the sessions are not stored somewhere nothing bad will happen, except from a few unecessary uploads, which could have been resumed.
    /// - Parameter onSuccess: Called on succeful completion of the process. Provides the uploaded measurements device wide unique identifier as a parameter.
    /// - Parameter onFailure: Called on failed upload process. Provides the measurements device wide unique identifier of the measurement, that failed to upload, together with the error information.
    public init(apiUrl: URL, session: Session = AF, sessionRegistry: SessionRegistry, authenticator: Authenticator, onSuccess: @escaping (Upload) -> Void, onFailure: @escaping (Upload, Error) -> Void) {
        self.openSessions = sessionRegistry
        self.apiUrl = apiUrl
        self.onSuccess = onSuccess
        self.onFailure = onFailure
        self.session = session
        self.authenticator = authenticator
    }

    /// Start the upload process for the provided `Upload`.
    func upload(_ upload: Upload) {
        authenticator.authenticate(onSuccess: { token in
            self.onSuccessfulAuthentication(authToken: token, upload: upload)
        }, onFailure: { error in
            self.onFailure(upload, error)
        })
    }

    /// Called after authentication with the Cyface data collector service was successful.
    private func onSuccessfulAuthentication(authToken: String, upload: Upload) {
        if let currentSession = openSessions.session(for: upload) {
            let statusRequest = StatusRequest(apiUrl: apiUrl, session: session, authToken: authToken)

            statusRequest.request(
                sessionIdentifier: currentSession,
                upload: upload,
                onFinished: onSuccess,
                onResume: onSuccessfulStatusRequest,
                onAborted: onAbortedStatusRequest,
                onFailure: onFailure
            )
        } else {
            let preRequest = PreRequest(apiUrl: apiUrl, session: session)

            preRequest.request(authToken: authToken, upload: upload, onSuccess: onSuccessfulPreRequest, onFailure: onFailure)
        }
    }

    /// Called after a status request on an open session returned successfully.
    private func onSuccessfulStatusRequest(authToken: String, sessionIdentifier: String, upload: Upload) {
        let uploadRequest = UploadRequest(session: session)

        uploadRequest.request(
            authToken: authToken,
            sessionIdentifier: sessionIdentifier,
            upload: upload,
            onSuccess: onSuccess,
            onFailure: onFailedUploadRequest)
    }

    /// Called if a status request was aborted by the server.
    private func onAbortedStatusRequest(authToken: String, upload: Upload) {
        let preRequest = PreRequest(apiUrl: apiUrl, session: session)

        preRequest.request(authToken: authToken, upload: upload, onSuccess: onSuccessfulPreRequest, onFailure: onFailure)
    }

    /// Called if an upload pre request was successful.
    private func onSuccessfulPreRequest(authToken: String, sessionIdentifier: String, upload: Upload) {
        let uploadRequest = UploadRequest(session: session)
        openSessions.register(session: sessionIdentifier, upload: upload)

        uploadRequest.request(
            authToken: authToken,
            sessionIdentifier: sessionIdentifier,
            upload: upload,
            onSuccess: onSuccess,
            onFailure: onFailedUploadRequest)
    }

    /// Called after a failed upload request.
    private func onFailedUploadRequest(authToken: String, sessionIdentifier: String, upload: Upload, error: Error) {
        var upload = upload
        upload.failedUploadsCounter += 1

        if upload.failedUploadsCounter > 3 {
            upload.failedUploadsCounter = 0
            onFailure(upload, error)
        } else {
            let statusRequest = StatusRequest(apiUrl: apiUrl, session: session, authToken: authToken)

            statusRequest.request(
                sessionIdentifier: sessionIdentifier,
                upload: upload,
                onFinished: onSuccess,
                onResume: onSuccessfulStatusRequest,
                onAborted: onAbortedStatusRequest,
                onFailure: onFailure
            )
        }
    }

}
