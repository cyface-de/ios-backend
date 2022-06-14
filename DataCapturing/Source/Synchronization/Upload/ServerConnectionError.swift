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
 A structure encapsulating errors used by server connections.

 - Author: Klemens Muthmann
 - Version: 5.0.0
 - Since: 1.0.0
 */
public enum ServerConnectionError: Error {
    /// If authentication was carried out but was not successful.
    case authenticationNotSuccessful(String)
    /// Error occuring if this client tried to communicate with the server without proper authentication.
    case notAuthenticated(String)
    /// Thrown if modality type changes are inconsistent.
    case modalityError(String)
    /// Thrown if measurement events are inconsistent.
    case measurementError(Int64)
    /// Thrown if some measurement metadata was not encodable as an UTF-8 String.
    case dataError(String)
    /// Rethrow an error from within Alamofire.
    case alamofireError(AFError)
    /// Server did not send a response and client timed out.
    case noResponse
    /// The request failed. The failure status code is provided.
    case requestFailed(httpStatusCode: Int)
    /// Missing location header in pre request response.
    case noLocation
    /// The upload location provided by a status request was no a valid URL.
    case invalidUploadLocation(String)
}
