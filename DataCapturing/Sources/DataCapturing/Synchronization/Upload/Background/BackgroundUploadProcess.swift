//
//  File.swift
//  
//
//  Created by Klemens Muthmann on 26.02.24.
//

import Foundation
import OSLog

/**
 An `UploadProcess` that keeps running in the background even after the app was terminated.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
class BackgroundUploadProcess: NSObject {
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

    init(
        builder: BackgroundUploadProcessBuilder,
        sessionRegistry: SessionRegistry,
        collectorUrl: URL,
        uploadFactory: UploadFactory
    ) {
        self.builder = builder
        self.sessionRegistry = sessionRegistry
        self.collectorUrl = collectorUrl
        self.uploadFactory = uploadFactory
    }
}

extension BackgroundUploadProcess: UploadProcess {
    func upload(measurement: FinishedMeasurement, authToken: String) async throws -> any Upload {
        /// Check for an open session.
        if let upload = try sessionRegistry.get(measurement: measurement) {
            /// If there is an open session continue by sending a status request
            let statusRequest = BackgroundStatusRequest(
                session: discretionaryUrlSession,
                bearerAuthToken: authToken,
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
                authToken: authToken,
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
        let measurementIdentifier = UInt64(descriptionPieces[1])

        switch responseType {
        case "STATUS":
            os_log("STATUS: %{PUBLIC}@", log: OSLog.synchronization, type: .debug, url.absoluteString)
            // TODO: Add proper error handling here
            try? onReceivedStatusRequest(httpStatusCode: response.statusCode)
        case "PREREQUEST":
            os_log("PREREQUEST: %{PUBLIC}@", log: OSLog.synchronization, type: .debug, url.absoluteString)
            let locationValue = response.value(forHTTPHeaderField: "Location") ?? "No Location"
            os_log("Upload - Received PreRequest to %@", log: OSLog.synchronization, type: .debug, locationValue)
            //os_log("Location: \(response.allHeaderFields["Location"] ?? "NO VALUE")")
            try? onReceivedPreRequest(httpStatusCode: response.statusCode)
        default:
            os_log("%{PUBLIC}@", log: OSLog.synchronization, type: .debug, description)
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

    private func onReceivedStatusRequest(httpStatusCode: Int) throws {
        switch httpStatusCode {
        case 200:
            os_log("200", log: OSLog.synchronization, type: .debug)
            //return Response.finished
            // Upload abgeschlossen. Ignorieren
        case 308:
            os_log("308", log: OSLog.synchronization, type: .debug)
            //return Response.resume
            // Upload fortsetzen
        case 404:
            os_log("404", log: OSLog.synchronization, type: .debug)
            //return Response.aborted
            // Upload neu starten
        default:
            os_log("%{PUBLIC}d", log: OSLog.synchronization, type: .debug, httpStatusCode)
            throw ServerConnectionError.requestFailed(httpStatusCode: httpStatusCode)
        }
    }

    private func onReceivedPreRequest(httpStatusCode: Int) throws {
        switch httpStatusCode {
        case 200:
            os_log("200", log: OSLog.synchronization, type: .debug)
            /*guard let location = response.value(forHTTPHeaderField: "Location") else {
                throw ServerConnectionError.noLocation
            }*/

            //return .success(location: location)
        case 409:
            os_log("409", log: OSLog.synchronization, type: .debug)
            //return .exists
        case 412:
            os_log("412", log: OSLog.synchronization, type: .debug)
            //throw ServerConnectionError.uploadNotAccepted(upload: upload)
        default:
            os_log("%{PUBLIC}d", log: OSLog.synchronization, type: .debug, httpStatusCode)
            throw ServerConnectionError.requestFailed(httpStatusCode: httpStatusCode)
        }
    }
}
