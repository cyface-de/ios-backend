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
 A request telling the server, that the app wants to upload a measurement.

 The server can either accept this and return a resource on which to start the upload or turn it down if it has no interest in the data.

 - author: Klemens Muthmann
 - version: 1.0.0
 */
class PreRequest {
    /// A URL running an appropriate Cyface Server
    let apiUrl: URL
    /// The Alamofire `Session` to use for uploading the data.
    let session: Session


    /// Make a new pre request from a Cyface API URL and an Alamofire `Session`.
    init(apiUrl: URL, session: Session) {
        self.apiUrl = apiUrl
        self.session = session
    }

    /// Send the request
    /// - Parameter authToken: Get this JWT token from an `Authenticator`.
    /// - Parameter upload: The upload information
    /// - Parameter onSuccess: Callback after the request finished successfully.
    /// - Parameter onFailure: Callback after the request failed for some reason.
    func request(authToken: String, upload: Upload, onSuccess: @escaping (String, String, Upload) -> Void, onFailure: @escaping (UInt64, Error) -> Void) {
        do {
            let metaData = try upload.metaData()
            let data = try upload.data()

            var headers: HTTPHeaders = []
            headers.add(name: "Content-Type", value: "application/json; charset=UTF-8")
            headers.add(name: "Authorization", value: "Bearer \(authToken)")
            headers.add(name: "x-upload-content-length", value: "\(data.count)")
            headers.add(name: "x-upload-content-type", value: "application/octet-stream")
            headers.add(name: "Accept-Encoding", value: "gzip")
            headers.add(name: "User-Agent", value: "Cyface-iOS-Client/\(metaData.applicationVersion) (gzip)")
            headers.add(name: "Connection", value: "Keep-Alive")

            let measurementIdentifier = metaData.measurementId

            session.request(
                apiUrl.appendingPathComponent("measurements"),
                method: .post,
                parameters: metaData,
                encoder: JSONParameterEncoder.default,
                headers: headers
            ).response { response in

                guard let response = response.response else {
                    if let error = response.error {
                        onFailure(measurementIdentifier, ServerConnectionError.alamofireError(error))
                    } else {
                        onFailure(measurementIdentifier, ServerConnectionError.noResponse)
                    }
                    return
                }

                let status = response.statusCode

                if status == 200 {
                    guard let location = response.headers["Location"] else {
                        onFailure(measurementIdentifier, ServerConnectionError.noLocation)
                        return
                    }

                    onSuccess(authToken, location, upload)
                } else if status == 412 {
                    onFailure(measurementIdentifier, ServerConnectionError.uploadNotAccepted(measurementIdentifier: Int64(measurementIdentifier)))
                } else {
                    onFailure(measurementIdentifier, ServerConnectionError.requestFailed(httpStatusCode: status))
                }
            }
        } catch {
            onFailure(upload.identifier, error)
        }
    }
}
