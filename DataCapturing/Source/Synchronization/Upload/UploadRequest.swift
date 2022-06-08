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
import OSLog

/**
 The actual upload requests sends captured data to a Cyface server.

 - author: Klemens Muthmann
 */
class UploadRequest {
    /// The URL to the Cyface API receiving the data.
    let session: Session
    /// The logger used by objects of this class.
    let log: OSLog = OSLog(subsystem: "UploadRequest", category: "de.cyface")

    /// Initialize the request using the provided Alamofire `Session` for execution.
    init(session: Session) {
        self.session = session
    }

    func request(authToken: String, sessionIdentifier: String, upload: Upload, continueOnByte: Int = 0, onSuccess: @escaping (UInt64) -> Void, onFailure: @escaping (String, String, Upload, Error) -> Void) {
        os_log("Uploading measurement %{public}d to session %{public}@.", log: log, type: .debug, upload.identifier, sessionIdentifier)
            do {
                let metaData = try upload.metaData()
                let data = try upload.data()

                var headers = metaData.asHeader
                headers.add(name: "Content-Length", value: String(data.count-continueOnByte))
                headers.add(name: "Content-Range", value: "bytes \(continueOnByte)-\(data.count-1)/\(data.count)")

                session.upload(data[continueOnByte..<data.count], to: sessionIdentifier, method: .put, headers: headers).response { response in
                guard let response = response.response else {
                    if let error = response.error {
                        onFailure(authToken, sessionIdentifier, upload, error)
                    } else {
                        onFailure(authToken, sessionIdentifier, upload, ServerConnectionError.noResponse)
                    }
                    return
                }

                let status = response.statusCode

                if status == 201 {
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
