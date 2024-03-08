/*
 * Copyright 2024 Cyface GmbH
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

/**
 An `UploadProcess` that keeps running in the background even after the app was terminated.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
class BackgroundUploadProcess: NSObject {
    // MARK: - Properties
    // TODO: There should be only one URLSession per App. Make sure this gets injected.
    /// A `URLSession` to use for sending requests and receiving responses, probably in the background.
    lazy var discretionaryUrlSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: DefaultUploadProcess.discretionaryUrlSessionIdentifier)
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
    /// The `UploadProcessBuilder` that created this `UploadProcess`.
    let builder: BackgroundUploadProcessBuilder
    var sessionRegistry: SessionRegistry
    let collectorUrl: URL
    let uploadFactory: UploadFactory
    let dataStoreStack: DataStoreStack
    let authenticator: Authenticator

    // MARK: - Initializers
    init(
        builder: BackgroundUploadProcessBuilder,
        sessionRegistry: SessionRegistry,
        collectorUrl: URL,
        uploadFactory: UploadFactory,
        dataStoreStack: DataStoreStack,
        authenticator: Authenticator
    ) {
        self.builder = builder
        self.sessionRegistry = sessionRegistry
        self.collectorUrl = collectorUrl
        self.uploadFactory = uploadFactory
        self.dataStoreStack = dataStoreStack
        self.authenticator = authenticator
    }

    // MARK: - Methods
    private func onReceivedStatusRequest(httpStatusCode: Int16, upload: any Upload) throws {
        switch httpStatusCode {
        case 200: // Upload abgeschlossen. Ignorieren
            os_log("200", log: OSLog.synchronization, type: .debug)
            try sessionRegistry.remove(upload: upload)

        case 308: // Upload fortsetzen
            os_log("308", log: OSLog.synchronization, type: .debug)
            try sessionRegistry.record(
                upload: upload,
                RequestType.status,
                httpStatusCode: httpStatusCode,
                message: "Permanent Redirect",
                time: Date.now)
            Task {
                let uploadRequest = BackgroundUploadRequest(
                    session: discretionaryUrlSession,
                    authToken: try await authenticator.authenticate(),
                    upload: upload
                )
                try uploadRequest.send()
            }

        case 404: // Upload neu starten
            os_log("404", log: OSLog.synchronization, type: .debug)
            try sessionRegistry.record(
                upload: upload,
                RequestType.status,
                httpStatusCode: httpStatusCode,
                message: "Not Found",
                time: Date.now
            )
            Task {
                let preRequest = BackgroundPreRequest(
                    collectorUrl: collectorUrl,
                    session: discretionaryUrlSession,
                    upload: upload,
                    authToken: try await authenticator.authenticate(),
                    sessionRegistry: sessionRegistry)
                try preRequest.send()
            }

        default:
            os_log("Error: %{PUBLIC}d", log: OSLog.synchronization, type: .debug, httpStatusCode)
            try sessionRegistry.remove(upload: upload)
            throw ServerConnectionError.requestFailed(httpStatusCode: Int(httpStatusCode))
        }
    }

    private func onReceivedPreRequest(httpStatusCode: Int16, upload: any Upload) throws {
        switch httpStatusCode {
        case 200: // Send Upload Request
            os_log("200", log: OSLog.synchronization, type: .debug)

            try sessionRegistry.record(
                upload: upload,
                RequestType.prerequest,
                httpStatusCode: httpStatusCode,
                message: "OK",
                time: Date.now
            )
            Task {
                let uploadRequest = BackgroundUploadRequest(
                    session: discretionaryUrlSession, 
                    authToken: try await authenticator.authenticate(),
                    upload: upload
                )
                try uploadRequest.send()
            }
        case 409: // Upload exists: Cancel and mark as finished
            os_log("409", log: OSLog.synchronization, type: .debug)
            try sessionRegistry.remove(upload: upload)

        case 412: // Server does not accept this upload. Cancel and mark as finished
            os_log("412", log: OSLog.synchronization, type: .debug)
            try sessionRegistry.remove(upload: upload)

        default:
            os_log("Error: %{PUBLIC}d", log: OSLog.synchronization, type: .debug, httpStatusCode)
            try sessionRegistry.remove(upload: upload)
            throw ServerConnectionError.requestFailed(httpStatusCode: Int(httpStatusCode))
        }
    }

    private func onReceivedUploadResponse(httpStatusCode: Int, upload: any Upload) throws {
        switch httpStatusCode {
        case 201:
            os_log("201", log: OSLog.synchronization, type: .debug)
            try sessionRegistry.remove(upload: upload)
        default:
            os_log("Error: %{PUBLIC}d", log: OSLog.synchronization, type: .error, httpStatusCode)
            try sessionRegistry.remove(upload: upload)
        }
    }
}

// MARK: - Implementation of UploadProcess
extension BackgroundUploadProcess: UploadProcess {
    func upload(measurement: FinishedMeasurement, authToken: String) async throws -> any Upload {
        /// Check for an open session.
        if let upload = try sessionRegistry.get(measurement: measurement) {
            /// If there is an open session continue by sending a status request
            let statusRequest = BackgroundStatusRequest(
                session: discretionaryUrlSession,
                bearerAuthToken: try await authenticator.authenticate(),
                upload: upload
            )
            try statusRequest.send()
            /// If the status request was successful continue by sending an upload starting at the byte given by the status request
            /// If the status request was not successful contnue with a pre request
            return upload
        } else {
            /// If there is no open session continue by sending a pre request
            let upload = uploadFactory.upload(for: measurement)
            try sessionRegistry.register(upload: upload)
            let preRequest = BackgroundPreRequest(
                collectorUrl: collectorUrl,
                session: discretionaryUrlSession,
                upload: upload,
                authToken: try await authenticator.authenticate(),
                sessionRegistry: sessionRegistry
            )
            try preRequest.send()
            /// If the pre request was successful create a session and start uploading the data
            /// If the upload request completes see if another chunk is due to be uploaded
            /// If yes than start the upload for the next chunk
            /// If not report successful completion
            /// If the upload request failed finish by reporting the error
            /// if the pre request fails finish by reporting the error
            return upload
        }
    }
}

// MARK: - Implementation of Delegates for URLSession
extension BackgroundUploadProcess: URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let response = task.response as? HTTPURLResponse else {
            os_log("Upload response not received!", log: OSLog.synchronization, type: .error)
            //self.error = ServerConnectionError.noResponse
            return
        }
        os_log("Upload response received!", log: OSLog.synchronization, type: .debug)

        if let error = error {
            os_log("Upload Error: %{PUBLIC}d", log: OSLog.synchronization, type: .error, error.localizedDescription)
            // TODO: Add proper error handling here
            return
        }
        os_log("Upload was successful!", log: OSLog.synchronization, type: .debug)

        guard let url = response.url else {
            os_log("Upload - No URL returned from response!", log: OSLog.synchronization, type: .error)
            return
        }
        os_log("Upload targeted URL: %{PUBLiC}@", log: OSLog.synchronization, type: .debug, url.absoluteString)

        guard let description = task.taskDescription else {
            os_log("Upload - No task description aborting upload!", log: OSLog.synchronization, type: .error)
            return
        }
        os_log("Upload described as %{PUBLIC}@!", log: OSLog.synchronization, type: .debug, description)
        let descriptionPieces = description.split(separator: ":")
        guard descriptionPieces.count == 2 else {
            os_log("Upload - Invalid task description %@.", log: OSLog.synchronization, type: .error, description)
            return
        }
        let responseType = descriptionPieces[0]
        guard let measurementIdentifier = UInt64(descriptionPieces[1]) else {
            return
        }

        do {
            let measurement = try dataStoreStack.wrapInContextReturn { context in
                let request = MeasurementMO.fetchRequest()
                request.predicate = NSPredicate(format: "identifier=%d", measurementIdentifier)
                request.fetchLimit = 1
                guard let storedMeasurement = try request.execute().first else {
                    throw PersistenceError.measurementNotLoadable(measurementIdentifier)
                }
                return try FinishedMeasurement(managedObject: storedMeasurement)
            }
            guard var upload = try sessionRegistry.get(measurement: measurement) else {
                throw PersistenceError.sessionNotRegistered(measurement)
            }

            switch responseType {
            case "STATUS":
                os_log("STATUS: %{PUBLIC}@", log: OSLog.synchronization, type: .debug, url.absoluteString)
                // TODO: Add proper error handling here
                try? onReceivedStatusRequest(httpStatusCode: Int16(response.statusCode), upload: upload)
            case "PREREQUEST":
                os_log("PREREQUEST: %{PUBLIC}@", log: OSLog.synchronization, type: .debug, url.absoluteString)
                let locationValue = response.value(forHTTPHeaderField: "Location") ?? "No Location"
                os_log("Upload - Received PreRequest to %@", log: OSLog.synchronization, type: .debug, locationValue)
                guard let locationUrl = URL(string: locationValue) else {
                    throw ServerConnectionError.invalidUploadLocation(locationValue)
                }
                upload.location = locationUrl
                try? onReceivedPreRequest(httpStatusCode: Int16(response.statusCode), upload: upload)
            case "UPLOAD":
                os_log("UPLOAD", log: OSLog.synchronization, type: .debug)
                try onReceivedUploadResponse(httpStatusCode: response.statusCode, upload: upload)
            default:
                os_log("%{PUBLIC}@", log: OSLog.synchronization, type: .debug, description)
            }
        } catch {
            os_log("%{PUBLIC}d", log: OSLog.synchronization, type: .error, error.localizedDescription)
        }


        // TODO
        //lastUploadStatus = httpResponse.statusCode
        //delegate?.errorInvalid()
    }

    @objc(URLSessionDidFinishEventsForBackgroundURLSession:) public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        os_log("Finished background session", log: OSLog.synchronization, type: .info)
        DispatchQueue.main.async { [weak self] in
            if let completionHandler = self?.builder.completionHandler {
                self?.builder.completionHandler = nil
                completionHandler()
            }
        }
    }
}
