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
 The actual upload requests sends captured data to a Cyface server.

 - author: Klemens Muthmann
 */
class UploadRequest {
    /// The URL to the Cyface API receiving the data.
    let apiUrl: URL
    let session: Session

    init(apiUrl: URL, session: Session) {
        self.apiUrl = apiUrl
        self.session = session
    }

    func request(authToken: String, sessionIdentifier: String, upload: Upload, continueOnByte: Int = 0, onSuccess: @escaping (UInt64) -> (), onFailure: @escaping (String, String, Upload, Error) -> ()) {
            do {
                let metaData = try upload.metaData()
                let data = upload.data()

                var headers = metaData.asHeader
                headers.add(name: "Content-Length", value: String(data.count-continueOnByte))
                headers.add(name: "Content-Range", value: "bytes \(continueOnByte)-\(data.count-1)/\(data.count)")

                let uploadLocation = apiUrl.appendingPathComponent("measurements").appendingPathComponent(sessionIdentifier)
                session.upload(data[continueOnByte..<data.count], to: uploadLocation, method: .put, headers: headers).response { response in
                guard let response = response.response else {
                    if let error = response.error {
                        onFailure(authToken, sessionIdentifier, upload, error)
                    } else {
                        onFailure(authToken, sessionIdentifier, upload, ServerConnectionError.noResponse)
                    }
                    return
                }

                let status = response.statusCode

                if status == 200 {
                    onSuccess(upload.identifier)
                } else {
                    onFailure(authToken, sessionIdentifier, upload, ServerConnectionError.requestFailed(httpStatusCode: status))
                }
            }
        } catch {
            onFailure(authToken, sessionIdentifier, upload, error)
        }
    }
}
