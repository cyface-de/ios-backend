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

/**
 A Google Media Upload Protocol pre request, that can be run in the background, as soon as that is convenient for the system.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
struct BackgroundPreRequest {
    let collectorUrl: URL
    let session: URLSession
    let upload: any Upload
    let authToken: String
    /// Encoder to write the meta data as JSON into the requests body.
    let jsonEncoder = JSONEncoder()
    var sessionRegistry: SessionRegistry

    func send() throws {
        let metaData = try upload.metaData()
        let data = try upload.data()
        let httpMethod = "POST"

        let requestUrl = collectorUrl.appendingPathComponent("measurements")

        var request = URLRequest(url: requestUrl)
        request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("\(data.count)", forHTTPHeaderField: "x-upload-content-length")
        request.setValue("application/octet-stream", forHTTPHeaderField: "x-upload-content-type")
        request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("Cyface-iOS-Client/\(metaData.applicationVersion) (gzip)", forHTTPHeaderField: "User-Agent")
        request.setValue("Keep-Alive", forHTTPHeaderField: "Connection")
        request.httpMethod = httpMethod

        let jsonData = try jsonEncoder.encode(metaData)
        let file = storeToBackgroundFile(data: jsonData)
        print("Creating PreRequest with token \(authToken)")
        let preRequestTask = session.uploadTask(with: request, fromFile: file)
        preRequestTask.countOfBytesClientExpectsToSend = headerBytes(request) + Int64(httpMethod.lengthOfBytes(using: .utf8)) + Int64(jsonData.count)
        // Only two headers "Content-Length" and "Range" are returned in the "worst" case. This is something higher then 30 bytes. The only variable is the value of the Range header, which depends on the actual range string returned. Even for large files, this should in sum with the other fields never exceed 50 bytes.
        preRequestTask.countOfBytesClientExpectsToReceive =
            // Location Header
            Int64("Location".count) +
            // The Location Header value is a URL. Appareantly they should be 2000 Bytes or less: https://stackoverflow.com/questions/417142/what-is-the-maximum-length-of-a-url-in-different-browsers
            2_000 +
            // The Content Length Header
            Int64("Content-Length".count) +
            // The Content Length value string in number of one byte long characters. This is close to one terrabyte of data, which should be plenty even for the most extreme measurements (there are currently no phones with that much storage, but we will surely be going there).
            12

        preRequestTask.taskDescription = "PREREQUEST:\(upload.measurement.identifier)"
        preRequestTask.resume()
        /*guard let response = response as? HTTPURLResponse else {
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
        }*/
    }

    private func headerBytes(_ request: URLRequest) -> Int64 {
        if let fields = request.allHTTPHeaderFields {
            return fields.map { (key:String, value:String) in
                return Int64(key.lengthOfBytes(using: .utf8))+Int64(value.lengthOfBytes(using: .utf8))
            }.reduce(0) { (first: Int64, second: Int64) in first+second }
        } else {
            return 0
        }
    }

    private func storeToBackgroundFile(data: Data) -> URL {
        // It is ok to store this to temporary storage, since iOS takes control of the file as soon as we hand it to the
        // upload task. This means premature removal of the file does not stop the output.
        // See: https://livefront.com/writing/uploading-data-in-the-background-in-ios/
        let tempDir = FileManager.default.temporaryDirectory
        let localURL = tempDir.appendingPathComponent("upload-data")
        try? data.write(to: localURL)

        return localURL
    }
}
