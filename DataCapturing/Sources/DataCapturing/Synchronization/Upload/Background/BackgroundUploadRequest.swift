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
import OSLog

/**
 A request to send the data from a ``FinishedMeasurement`` to a Cyface Collector Server.

 Before sending such a request a ``BackgroundPreRequest`` must have finished successfully, setting the ``Upload/location`` to the correct session for this request.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
struct BackgroundUploadRequest {
    // MARK: - Properties
    /// The URL to the Cyface API receiving the data.
    let session: URLSession
    /// The logger used by objects of this class.
    let log: OSLog = OSLog(subsystem: "UploadRequest", category: "de.cyface")
    /// The ``Upload`` to send to the Cyface Collector Server.
    let upload: any Upload
    /// Start the upload from this byte in the upload data.
    ///
    /// The default is 0. If a ``BackgroundStatusRequest`` provides a different value, the upload may start from there.
    /// This is usually the case if some data was uploaded previously and this is a continuation upload.
    let continueOnByte: Int = 0

    /// Send the request for the provided `upload`.
    func send() throws {
        os_log("Upload Request: Uploading measurement %{public}d to %{public}@.", log: log, type: .debug, upload.measurement.identifier, upload.location?.absoluteString ?? "Location Missing!")
        let metaData = try upload.metaData()
        let data = try upload.data()

        guard let url = upload.location else {
            throw ServerConnectionError.invalidUploadLocation("Missing Location")
        }

        // Background uploads are only valid from files, so writing the data to a file at first.
        let dataToUpload = data[continueOnByte..<data.count]
        let tempDataFile = try copyToTemp(data: dataToUpload, filename: url.lastPathComponent)

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        metaData.add(to: &request)
        request.setValue(String(data.count-continueOnByte), forHTTPHeaderField: "Content-Length")
        request.setValue("bytes \(continueOnByte)-\(data.count-1)/\(data.count)", forHTTPHeaderField: "Content-Range")

        let uploadTask = session.uploadTask(with: request, fromFile: tempDataFile)
        uploadTask.countOfBytesClientExpectsToSend = Int64(dataToUpload.count) + headerBytes(request)
        uploadTask.countOfBytesClientExpectsToReceive = minimumBytesInAnHTTPResponse
        uploadTask.taskDescription = "UPLOAD:\(upload.measurement.identifier)"
        uploadTask.resume()
    }
}
