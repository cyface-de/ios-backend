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
 */
class PreRequest {
    /// A URL running an appropriate Cyface Server
    let apiUrl: URL
    /// The Alamofire `Session` to use for uploading the data.
    let session: Session

    init(apiUrl: URL, session: Session) {
        self.apiUrl = apiUrl
        self.session = session
    }

    func request(authToken: String, upload: Upload, onSuccess: @escaping (String, String, Upload) -> (), onFailure: @escaping (UInt64, Error) -> ()) {
        do {
            let metaData = try upload.metaData()
            let data = upload.data()

            var headers = metaData.asHeader
            headers.add(name: "Content-Type", value: "application/json; charset=UTF-8")
            headers.add(name: "Authorization", value: "Bearer \(authToken)")
            // TODO: Calculate valid upload length
            headers.add(name: "x-upload-content-length", value: "\(data.count)")

            let measurementIdentifier = metaData.measurementId

            session.request(apiUrl.appendingPathComponent("measurements"), method: .post, parameters: metaData, encoder: JSONParameterEncoder.default, headers: headers).response { response in

                guard let response = response.response else {
                    if let error = response.error {
                        onFailure(measurementIdentifier, ServerConnectionError.alamofireError(error))
                    } else {
                        onFailure(measurementIdentifier, ServerConnectionError.noResponse)
                    }
                    return
                }

                let status = response.statusCode
                guard let location = response.headers["Location"] else {
                    onFailure(measurementIdentifier, ServerConnectionError.noLocation)
                    return
                }

                if status == 200 {
                    onSuccess(authToken, location, upload)
                } else {
                    onFailure(measurementIdentifier, ServerConnectionError.requestFailed(httpStatusCode: status))
                }
            }
        } catch {
            onFailure(upload.identifier, error)
        }
    }
}
