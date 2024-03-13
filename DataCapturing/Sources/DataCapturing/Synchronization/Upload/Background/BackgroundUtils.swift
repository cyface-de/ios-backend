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

/// The bytes within the most simple HTTP reponse, which only consists of the HTTP Status line, without any headers or a body.
let minimumBytesInAnHTTPResponse = Int64(45)

/// Calculate the size in bytes of an `URLRequest` header.
func headerBytes(_ request: URLRequest) -> Int64 {
    if let fields = request.allHTTPHeaderFields {
        return fields.map { (key:String, value:String) in
            return Int64(key.lengthOfBytes(using: .utf8))+Int64(value.lengthOfBytes(using: .utf8))
        }.reduce(0) { (first: Int64, second: Int64) in first+second }
    } else {
        return 0
    }
}

/// Copy the provided data to a temporary file with the provided `filename`.
///
/// This is used to store data for background uploads, as they are only valid from files.
func copyToTemp(data: Data, filename: String) throws -> URL {
    // It is ok to store this to temporary storage, since iOS takes control of the file as soon as we hand it to the
    // upload task. This means premature removal of the file does not stop the output.
    // See: https://livefront.com/writing/uploading-data-in-the-background-in-ios/
    let target = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
    if FileManager.default.fileExists(atPath: target.relativePath) {
        try FileManager.default.removeItem(at: target)
    }
    try data.write(to: target)
    return target
}
