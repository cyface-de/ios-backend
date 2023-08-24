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

/**
 A request send to receive status information about an open upload session from the server.
 
 - author: Klemens Muthmann
 - version: 1.0.0
 */
class StatusRequest {
    /// The Cyface API URL to send the request to.
    let apiUrl: URL
    /// The Alamofire `Session` to upload data with.
    let session: Session
    /// JWT token to authenticate with. Get one by using an `Authenticator`.
    let authToken: String
    
    /// Make a new request for a specific Cyface API.
    init(apiUrl: URL, session: Session, authToken: String) {
        self.apiUrl = apiUrl
        self.session = session
        self.authToken = authToken
    }
    
    /// Start the request
    /// - Parameter sessionIdentifier: The URL to the open session for which to request status information.
    /// - Parameter upload: The data to upload.
    func request(
        sessionIdentifier: String,
        upload: Upload
    ) async throws -> Response {
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
            throw ServerConnectionError.invalidUploadLocation(sessionIdentifier)
        }
        
        let response = await session.request(requestUrl, method: .put).serializingData().response
        guard let response = response.response else {
            if let error = response.error {
                throw ServerConnectionError.alamofireError(error)
            } else {
                throw ServerConnectionError.noResponse
            }
        }
        
        switch response.statusCode {
        case 200:
            return Response.finished
            // Upload abgeschlossen. Ignorieren
        case 308:
            return Response.resume
            // Upload fortsetzen
        case 404:
            return Response.aborted
            // Upload neu starten
        default:
            throw ServerConnectionError.requestFailed(httpStatusCode: response.statusCode)
        }
    }
    
    enum Response {
        /// When the status was that the request has been finished.
        case finished
        /// When the status was that the request should be resumed.
        case resume
        /// When the status was that the request was aborted, for example if it timed out on server side.
        case aborted
    }
}
