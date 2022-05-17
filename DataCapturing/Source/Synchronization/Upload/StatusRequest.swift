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
            let data = try upload.data()

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
            guard let requestUrl = URL(string: sessionIdentifier) else {
                onFailure(upload.identifier, ServerConnectionError.invalidUploadLocation(sessionIdentifier))
                return
            }

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
