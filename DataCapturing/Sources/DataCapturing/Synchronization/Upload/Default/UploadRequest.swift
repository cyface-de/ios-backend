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
import OSLog

/**
 The actual upload requests sends captured data to a Cyface server.

 - author: Klemens Muthmann
 - version: 1.0.0
 - Since: 12.0.0
 */
class UploadRequest {
    /// The URL to the Cyface API receiving the data.
    let session: URLSession
    /// The logger used by objects of this class.
    let log: OSLog = OSLog(subsystem: "UploadRequest", category: "de.cyface")

    /// Initialize the request using the provided Alamofire `Session` for execution.
    init(session: URLSession) {
        self.session = session
    }

    /// Send the request for the provided `upload`.
    func request(authToken: String, upload: any Upload, continueOnByte: Int = 0) async throws -> any Upload {
        os_log("Uploading measurement %{public}d to %{public}@.", log: log, type: .debug, upload.measurement.identifier, upload.location?.absoluteString ?? "Location Missing!")
        let metaData = try upload.metaData()
        let data = try upload.data()

        guard let url = upload.location else {
            throw ServerConnectionError.invalidUploadLocation("Missing Location")
        }

        // Background uploads are only valid from files, so writing the data to a file at first.
        let tempDataFile = try copyToTemp(data: data[continueOnByte..<data.count], filename: url.lastPathComponent)

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        metaData.add(to: &request)
        request.setValue(String(data.count-continueOnByte), forHTTPHeaderField: "Content-Length")
        request.setValue("bytes \(continueOnByte)-\(data.count-1)/\(data.count)", forHTTPHeaderField: "Content-Range")

        let (_, response) = try await session.upload(for: request, fromFile: tempDataFile)
        guard let response = response as? HTTPURLResponse else {
            throw ServerConnectionError.noResponse
        }

        let status = response.statusCode

        if status == 201 {
            return upload
        } else {
            throw ServerConnectionError.requestFailed(httpStatusCode: status)
        }
    }
}
