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
 A request telling the server, that the app wants to upload a measurement.

 The server can either accept this and return a resource on which to start the upload or turn it down if it has no interest in the data.

 - author: Klemens Muthmann
 - version: 1.0.0
 */
class PreRequest {
    /// A URL running an appropriate Cyface Server
    let apiUrl: URL
    /// The Alamofire `Session` to use for uploading the data.
    let session: URLSession
    /// Encoder to write the meta data as JSON into the requests body.
    let jsonEncoder = JSONEncoder()

    /// Make a new pre request from a Cyface API URL and an Alamofire `Session`.
    init(apiUrl: URL, session: URLSession) {
        self.apiUrl = apiUrl
        self.session = session
    }

    /// Send the request
    /// - Parameter authToken: Get this JWT token from an `Authenticator`.
    /// - Parameter upload: The upload information
    func request(authToken: String, upload: Upload) async throws -> Response {
        let metaData = try upload.metaData()
        let data = try upload.data()

        let requestUrl = apiUrl.appendingPathComponent("measurements")

        var request = URLRequest(url: requestUrl)
        request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("\(data.count)", forHTTPHeaderField: "x-upload-content-length")
        request.setValue("application/octet-stream", forHTTPHeaderField: "x-upload-content-type")
        request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("Cyface-iOS-Client/\(metaData.applicationVersion) (gzip)", forHTTPHeaderField: "User-Agent")
        request.setValue("Keep-Alive", forHTTPHeaderField: "Connection")
        request.httpMethod = "POST"

        let jsonData = try jsonEncoder.encode(metaData)
        let (_, response) = try await session.upload(for: request, from: jsonData)
        guard let response = response as? HTTPURLResponse else {
                throw ServerConnectionError.noResponse
        }

        let status = response.statusCode

        if status == 200 {
            guard let location = response.value(forHTTPHeaderField: "Location") else {
                throw ServerConnectionError.noLocation
            }

            return .success(location: location)
        } else if status == 409 {
            return .exists
        } else if status == 412 {
            throw ServerConnectionError.uploadNotAccepted(upload: upload)
        } else {
            throw ServerConnectionError.requestFailed(httpStatusCode: status)
        }
    }

    enum Response {
        case success(location: String)
        case exists
    }
}
