//
//  StatusRequest.swift
//  DataCapturing
//
//  Created by Klemens Muthmann on 17.03.22.
//

import Foundation
import Alamofire

class StatusRequest {

    let apiUrl: URL
    let session: Session

    init(apiUrl: URL, session: Session) {
        self.apiUrl = apiUrl
        self.session = session
    }

    func request(authToken: String, sessionIdentifier: String, upload: Upload, onFinished: @escaping (UInt64) -> (), onResume: @escaping (String, String, Upload) -> (), onAborted: @escaping (String, Upload) -> (), onFailure: @escaping (UInt64, Error) -> ()) {
        do {
            let metaData = try upload.metaData()
            let data = upload.data()

            var headers = metaData.asHeader
            guard let host = apiUrl.host else {
                fatalError()
            }
            headers.add(name: "Authorization", value: "Bearer \(authToken)")
            headers.add(name: "Accept-Encoding", value: "gzip")
            headers.add(name: "User-Agent", value: "Google-HTTP-Java-Client/1.39.2 (gzip)")
            headers.add(name: "Content-Type", value: "application/octet-stream")
            headers.add(name: "Host", value: host)
            headers.add(name: "Connection", value: "Keep-Alive")
            // empty body
            headers.add(name: "content-length", value: "0")
            // ask where to continue, here: "how much of the 4 bytes upload did you receive?"
            // always send the total upload size, no matter if you did just sent a chunk
            headers.add(name: "Content-Range", value: "bytes */\(data.count)")
            let requestUrl = apiUrl.appendingPathComponent("measurements").appendingPathComponent(sessionIdentifier)

            session.request(requestUrl, method: .put).response { response in
                guard let response = response.response else {
                    if let error = response.error {
                        return onFailure(upload.identifier, ServerConnectionError.alamofireError(error))
                    } else {
                        return onFailure(upload.identifier, ServerConnectionError.noResponse)
                    }
                }

                switch response.statusCode {
                case 200:
                    onFinished(upload.identifier)
                    // Upload abgeschlossen. Ignorieren
                case 308:
                    onResume(authToken, sessionIdentifier, upload)
                    // Upload fortsetzen
                case 404:
                    onAborted(authToken, upload)
                    // Upload neu starten
                default:
                    onFailure(upload.identifier, ServerConnectionError.requestFailed(httpStatusCode: response.statusCode))
                }
            }
        } catch {
            onFailure(upload.identifier, error)
        }
    }
}
