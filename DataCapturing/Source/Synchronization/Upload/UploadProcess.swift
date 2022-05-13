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
    var openSessions: SessionRegistry
    let apiUrl: URL
    let onSuccess: (UInt64) -> Void
    let onFailure: (UInt64, Error) -> Void
    let session: Session
    let authenticator: Authenticator

    public init(apiUrl: URL, session: Session = AF, sessionRegistry: SessionRegistry, authenticator: Authenticator, onSuccess: @escaping (UInt64) -> Void, onFailure: @escaping (UInt64, Error) -> Void) {
        self.openSessions = sessionRegistry
        self.apiUrl = apiUrl
        self.onSuccess = onSuccess
        self.onFailure = onFailure
        self.session = session
        self.authenticator = authenticator
    }

    func upload(_ upload: Upload) {
        authenticator.authenticate(onSuccess: { token in
            self.onSuccessfulAuthentication(authToken: token, upload: upload)
        }, onFailure: { error in
            self.onFailure(upload.identifier, error)
        })
    }

    private func onSuccessfulAuthentication(authToken: String, upload: Upload) {
        if let currentSession = openSessions.session(for: upload) {
            let statusRequest = StatusRequest(apiUrl: apiUrl, session: session)

            statusRequest.request(
                authToken: authToken,
                sessionIdentifier: currentSession,
                upload: upload,
                onFinished: onSuccess,
                onResume: onSuccessfulStatusRequest,
                onAborted: onAbortedStatusRequest,
                onFailure: onFailure)
        } else {
            let preRequest = PreRequest(apiUrl: apiUrl, session: session)

            preRequest.request(authToken: authToken, upload: upload, onSuccess: onSuccessfulPreRequest, onFailure: onFailure)
        }
    }

    private func onSuccessfulStatusRequest(authToken: String, sessionIdentifier: String, upload: Upload) {
        let uploadRequest = UploadRequest(session: session)

        uploadRequest.request(
            authToken: authToken,
            sessionIdentifier: sessionIdentifier,
            upload: upload,
            onSuccess: onSuccess,
            onFailure: onFailedUploadRequest)
    }

    private func onAbortedStatusRequest(authToken: String, upload: Upload) {
        let preRequest = PreRequest(apiUrl: apiUrl, session: session)

        preRequest.request(authToken: authToken, upload: upload, onSuccess: onSuccessfulPreRequest, onFailure: onFailure)
    }

    private func onSuccessfulPreRequest(authToken: String, sessionIdentifier: String, upload: Upload) {
        let uploadRequest = UploadRequest(session: session)
        openSessions.register(session: sessionIdentifier, measurement: upload)

        uploadRequest.request(
            authToken: authToken,
            sessionIdentifier: sessionIdentifier,
            upload: upload,
            onSuccess: onSuccess,
            onFailure: onFailedUploadRequest)
    }

    private func onFailedUploadRequest(authToken: String, sessionIdentifier: String, upload: Upload, error: Error) {
        var upload = upload
        upload.failedUploadsCounter += 1

        if upload.failedUploadsCounter > 3 {
            upload.failedUploadsCounter = 0
            onFailure(upload.identifier, error)
        } else {
            let statusRequest = StatusRequest(apiUrl: apiUrl, session: session)

            statusRequest.request(
                authToken: authToken,
                sessionIdentifier: sessionIdentifier,
                upload: upload,
                onFinished: onSuccess,
                onResume: onSuccessfulStatusRequest,
                onAborted: onAbortedStatusRequest,
                onFailure: onFailure)
        }
    }

}
