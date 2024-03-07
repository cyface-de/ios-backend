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

struct BackgroundStatusRequest {
    let session: URLSession
    let bearerAuthToken: String
    let upload: any Upload

    /**
     - Throws: `ServerConnectionError.invalidUploadLocation` if the provided `sessionIdentifier` is invalid.
     */
    func send() throws {
        guard let requestLocation = upload.location else {
            throw ServerConnectionError.invalidUploadLocation("Missing Location")
        }

        guard let host = requestLocation.host else {
            throw ServerConnectionError.invalidUploadLocation(requestLocation.absoluteString)
        }

        let metaData = try upload.metaData()
        let data = try upload.data()
        let httpMethod = "PUT"

        var request = URLRequest(url: requestLocation)
        metaData.add(to: &request)
        request.setValue("Bearer \(bearerAuthToken)", forHTTPHeaderField: "Authorization")
        request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("Google-HTTP-Java-Client/1.39.2 (gzip)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.setValue(host, forHTTPHeaderField: "Host")
        request.setValue("Keep-Alive", forHTTPHeaderField: "Connection")
        // empty body
        request.setValue("0", forHTTPHeaderField: "content-length")
        // ask where to continue, here: "how much of the 4 bytes upload did you receive?"
        // always send the total upload size, no matter if you did just sent a chunk
        request.setValue("bytes */\(data.count)", forHTTPHeaderField: "Content-Range")
        request.httpMethod = httpMethod

        let statusRequestTesk = session.dataTask(with: request)
        statusRequestTesk.countOfBytesClientExpectsToSend = headerBytes(request) + Int64(httpMethod.lengthOfBytes(using: .utf8))
        // Only two headers "Content-Length" and "Range" are returned in the "worst" case. This is something higher then 30 bytes. The only variable is the value of the Range header, which depends on the actual range string returned. Even for large files, this should in sum with the other fields never exceed 50 bytes.
        statusRequestTesk.countOfBytesClientExpectsToReceive = 50 + minimumBytesInAnHTTPResponse
        statusRequestTesk.taskDescription = "STATUS:\(upload.measurement.identifier)"
        statusRequestTesk.resume()
    }
}