/*
 * Copyright 2022-2024 Cyface GmbH
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
 A structure encapsulating errors used by server connections.

 - Author: Klemens Muthmann
 */
public enum ServerConnectionError: Error {
    /// If authentication was carried out but was not successful. The username of the failed authentication attempt is provided as a parameter.
    case authenticationNotSuccessful(String)
    /// Error occuring if this client tried to communicate with the server without proper authentication.
    case notAuthenticated(String)
    /// Thrown if modality type changes are inconsistent.
    case modalityError(String)
    /// Thrown if some measurement metadata was not encodable as an UTF-8 String.
    case dataError(String)
    /// Server did not send a response and client timed out.
    case noResponse
    /// The request failed. The failure status code is provided.
    case requestFailed(httpStatusCode: Int)
    /// Missing location header in pre request response.
    case noLocation
    /// The upload location provided by a status request was no a valid URL.
    case invalidUploadLocation(String)
    /// Thrown if the server did not accept the upload of a measurement for some reason
    case uploadNotAccepted(upload: any Upload)
}

extension ServerConnectionError: LocalizedError {
    /// The internationalized error description providing further details about a thrown error.
    public var errorDescription: String? {
        switch self {
        case .authenticationNotSuccessful(let username):
            let errorMessage =  NSLocalizedString(
                "de.cyface.error.ServerConnectionError.authenticationNotSuccessful",
                value: "Authentication was not successful for user: %@",
                comment: """
Tell the user that authentication with the Cyface server for its credentials has failed! \
The username that was used is provided as the first parameter.
""")
            return String.localizedStringWithFormat(errorMessage, username)

        case .notAuthenticated(let reason):
            let errorMessage =  NSLocalizedString(
                "de.cyface.error.ServerConnectionError.notAuthenticated",
                value: "Your request was not authenticated with the server! Reason: %@",
                comment: """
Tell the user that its request did not have a valid authentication token and thus could not be carried out. \
The reason for this is provided as the first parameter.
""")
            return String.localizedStringWithFormat(errorMessage, reason)
        case .modalityError(let reason):
            let errorMessage =  NSLocalizedString(
                "de.cyface.error.ServerConnectionError.modalityError",
                value: "The modality of a measurement was invalid! Reason: %@",
                comment: """
Tell the user that applying the requested modality for failed for some reason. \
The reason is provided as the first parameter.
""")
            return String.localizedStringWithFormat(errorMessage, reason)
        case .dataError(let reason):
            let errorMessage =  NSLocalizedString(
                "de.cyface.error.ServerConnectionError.dataError",
                value: "Failed to process binary data! Reason: %@",
                comment: """
Tell the user that processing some binary data failed. \
The reason is provided as the first parameter.
""")
            return String.localizedStringWithFormat(errorMessage, reason)
        case .noResponse:
            let errorMessage =  NSLocalizedString(
                "de.cyface.error.ServerConnectionError.noResponse",
                value: "The server did not answer!",
                comment: """
Tell the user that the server did not answer to a request!
""")
            return errorMessage
        case .requestFailed(httpStatusCode: let httpStatusCode):
            let errorMessage =  NSLocalizedString(
                "de.cyface.error.ServerConnectionError.requestFailed",
                value: "Invalid HTTP status code %d!",
                comment: """
Tell the user that the server answered with a non successful error code. \
The code is provided as the first parameter
""")
            return String.localizedStringWithFormat(errorMessage, httpStatusCode)
        case .noLocation:
            let errorMessage =  NSLocalizedString(
                "de.cyface.error.ServerConnectionError.noLocation",
                value: "PreRequest did not provide upload location",
                comment: """
Tell the user that a pre request failed because no data upload location was provided.
""")
            return errorMessage
        case .invalidUploadLocation(let session):
            let errorMessage =  NSLocalizedString(
                "de.cyface.error.ServerConnectionError.invalidUploadLocation",
                value: "Upload session %@ was invalid!",
                comment: """
Tell the user that an upload failed because the session used for that upload was invalid.
""")
            return String.localizedStringWithFormat(errorMessage, session)
        case .uploadNotAccepted(upload: let upload):
            let errorMessage =  NSLocalizedString(
                "de.cyface.error.ServerConnectionError.uploadNotAccepted",
                value: "The server did not accept the upload of the measurement",
                comment: """
Tell the user that for some reason the server did not accept the upload of measurement %@.
There are several possible reasons for that, which are server specific.
One example would be a measurement without any location data.
""")
            return String.localizedStringWithFormat(errorMessage, upload.measurement.identifier)
        }
    }
}
