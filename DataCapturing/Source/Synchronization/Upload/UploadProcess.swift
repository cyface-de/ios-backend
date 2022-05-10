//
//  UploadProcess.swift
//  DataCapturing
//
//  Created by Klemens Muthmann on 17.03.22.
//

import Foundation
import Alamofire

// TODO: Repeat Request after Authentication has failed
// TODO: Repeat failed Requests a finite number of times, trying to restart on existing session

public class UploadProcess {
    let openSessions: SessionRegistry
    let apiUrl: URL
    let onSuccess: (UInt64) -> ()
    let onFailure: (UInt64, Error) -> ()
    let session: Session
    let authenticator: Authenticator

    init(apiUrl: URL, session: Session, sessionRegistry: SessionRegistry, authenticator: Authenticator, onSuccess: @escaping (UInt64) -> (), onFailure: @escaping (UInt64, Error) -> ()) {
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

            statusRequest.request(authToken: authToken, sessionIdentifier: currentSession, upload: upload, onFinished: onSuccess, onResume: onSuccessfulStatusRequest, onAborted: onAbortedStatusRequest, onFailure: onFailure)
        } else {
            let preRequest = PreRequest(apiUrl: apiUrl, session: session)

            preRequest.request(authToken: authToken, upload: upload, onSuccess: onSuccessfulPreRequest, onFailure: onFailure)
        }
    }

    private func onSuccessfulStatusRequest(authToken: String, sessionIdentifier: String, upload: Upload) {
        let uploadRequest = UploadRequest(apiUrl: apiUrl, session: session)

        uploadRequest.request(authToken: authToken, sessionIdentifier: sessionIdentifier, upload: upload, onSuccess: onSuccess, onFailure: onFailedUploadRequest)
    }

    private func onAbortedStatusRequest(authToken: String, upload: Upload) {
        let preRequest = PreRequest(apiUrl: apiUrl, session: session)

        preRequest.request(authToken: authToken, upload: upload, onSuccess: onSuccessfulPreRequest, onFailure: onFailure)
    }

    private func onSuccessfulPreRequest(authToken: String, sessionIdentifier: String, upload: Upload) {
        let uploadRequest = UploadRequest(apiUrl: apiUrl, session: session)

        uploadRequest.request(authToken: authToken, sessionIdentifier: sessionIdentifier, upload: upload, onSuccess: onSuccess, onFailure: onFailedUploadRequest)
    }

    private func onFailedUploadRequest(authToken: String, sessionIdentifier: String, upload: Upload, error: Error) {
        var upload = upload
        upload.failedUploadsCounter += 1

        if upload.failedUploadsCounter > 3 {
            upload.failedUploadsCounter = 0
            onFailure(upload.identifier, error)
        } else {
            let statusRequest = StatusRequest(apiUrl: apiUrl, session: session)

            statusRequest.request(authToken: authToken, sessionIdentifier: sessionIdentifier, upload: upload, onFinished: onSuccess, onResume: onSuccessfulStatusRequest, onAborted: onAbortedStatusRequest, onFailure: onFailure)
        }
    }

}
