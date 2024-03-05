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

/**
 A request send to receive status information about an open upload session from the server.
 
 - author: Klemens Muthmann
 - version: 1.0.0
 */
class StatusRequest {
    /// The Cyface API URL to send the request to.
    let apiUrl: URL
    /// The Alamofire `Session` to upload data with.
    let session: URLSession
    /// JWT token to authenticate with. Get one by using an `Authenticator`.
    let authToken: String
    
    /// Make a new request for a specific Cyface API.
    init(apiUrl: URL, session: URLSession, authToken: String) {
        self.apiUrl = apiUrl
        self.session = session
        self.authToken = authToken
    }
    
    /// Start the request
    /// - Parameter upload: The data to upload.
    func request(upload: any Upload) async throws -> Response {
        let metaData = try upload.metaData()
        let data = try upload.data()
        
        guard let host = apiUrl.host else {
            fatalError()
        }

        guard let requestUrl = upload.location else {
            throw ServerConnectionError.invalidUploadLocation("Missing Location")
        }

        var request = URLRequest(url: requestUrl)
        metaData.add(to: &request)
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("Google-HTTP-Java-Client/1.39.2 (gzip)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.setValue( host, forHTTPHeaderField: "Host")
        request.setValue("Keep-Alive", forHTTPHeaderField: "Connection")
        // empty body
        request.setValue("0", forHTTPHeaderField: "content-length")
        // ask where to continue, here: "how much of the 4 bytes upload did you receive?"
        // always send the total upload size, no matter if you did just sent a chunk
        request.setValue("bytes */\(data.count)", forHTTPHeaderField: "Content-Range")
        request.httpMethod = "PUT"

        let (_, response) = try await session.data(for: request)

        guard let response = response as? HTTPURLResponse else {
            throw ServerConnectionError.noResponse
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
