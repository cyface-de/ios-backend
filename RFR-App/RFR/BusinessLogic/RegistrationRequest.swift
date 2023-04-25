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

/// An HTTP request to a Cyface server to register a new user account.
///
/// @author: Klemens Muthmann
/// @version: 1.0.0
/// @since: 4.0.0
struct RegistrationRequest {

    /// The address of the server running the registration service.
    let url: URL

    /// Sends the request.
    ///
    /// - Parameters:
    ///   - username: The username of the user to create.
    ///   - password: The password of the user to create.
    ///   - validationToken: The HCaptcha validation token, which validates, that the request is from an actual human.
    func request(username: String, password: String, validationToken: String) async throws {

        let body = ["email" : username, "password": password, "captcha": validationToken]

        do {
            var request = try URLRequest(url: url, method: .post)
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw RegistrationError.invalidResponseType
            }

            switch httpResponse.statusCode {
            case 201: break
            case 400:
                throw RegistrationError.unexpectedClientError
            case 409:
                throw RegistrationError.emailUsed
            case 422:
                throw RegistrationError.erroneousRequest
            case 429:
                throw RegistrationError.tooManyRequests
            case 500:
                throw RegistrationError.unexpectedServerError
            default:
                throw RegistrationError.unexpectedStatusCode(statusCode: httpResponse.statusCode)
            }
        } catch {
            throw RegistrationError.internalError(cause: error)
        }
    }

}

/// An enumeration with all the possible errors thrown during a ``RegistrationRequest``.
///
/// - author: Klemens Muthmann
/// - version: 1.0.0
/// - since: 4.0.0
enum RegistrationError {
    case internalError(cause: Error)
    case invalidResponseType
    case unexpectedClientError
    case emailUsed
    case erroneousRequest
    case tooManyRequests
    case unexpectedServerError
    case unexpectedStatusCode(statusCode: Int)
}

extension RegistrationError: LocalizedError {
    /// An internationalized error description for all the different error cases.
    var errorDescription: String? {
        switch self {
        case .internalError(cause: let cause):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.RegistrationError.internalError",
                value: "An error from within your phone occurred while carrying out your registration request! The error details are:\n %@",
                comment: """
Tell the user that the iPhones software stack produced some error while trying to send a registration request.
The causing error message is provided as the first parameter and is of type String. It might not be internationalized!
""")
            return String.localizedStringWithFormat(errorMessage, cause.localizedDescription)
        case .invalidResponseType:
            let errorMessage = NSLocalizedString(
                "de.cyface.error.RegistrationError.invalidResponseType",
                value: "Response returned on registration request must be an HTTP response!",
                comment: """
Tell the user that the response the system got from sending a registration request was not of the correct type.
""")

            return errorMessage
        case .unexpectedClientError:
            let errorMessage = NSLocalizedString(
                "de.cyface.error.RegistrationError.unexpectedClientError",
                value: "Sending the response caused an unexpected error on client side! You are probably offline or not able to send the request at the moment. Please make sure you are online and can reach the Internet before trying again.",
                comment: """
Tell the user that an unexpected client error occurred. The most common cause is, that the user is offline.
""")

            return errorMessage
        case .emailUsed:
            let errorMessage = NSLocalizedString(
                "de.cyface.error.RegistrationError.emailUsed",
                value: "The e-mail address used for registration is already taken. Please try another e-mail address. If you forgot your password, please contact support, to reset!",
                comment: """
Tell the user that the e-mail address used for registration is not available anymore.
In such cases the user either uses an e-mail address not belonging to her/him/them or tries to reregister, which is not permitted.
To reset the password, the user needs to contact the Cyface support.
""")

            return errorMessage
        case .erroneousRequest:
            let errorMessage = NSLocalizedString(
                "de.cyface.error.RegistrationError.erroneousRequest",
                value: "Registration request was malformed! This can be caused if you are using and old version of the app, or if your request was scrambled during transmission. Try to update or try again. If the problem continues please contact support",
                comment: """
Tell the user that the registration request was not properly formatted.
Usually in such cases resending the request might work.
Otherwise it is possible that an old version of the app was used and an update is necessary.
""")

            return errorMessage
        case .tooManyRequests:
            let errorMessage = NSLocalizedString(
                "de.cyface.error.RegistrationError.tooManyRequests",
                value: "You tried to often to send requests to the Cyface server. Please wait a moment and try again!",
                comment: """
Tell the user that to many requests have been send in short succession by his phone. The user should try again after some time has passed.
""")

            return errorMessage
        case .unexpectedServerError:
            let errorMessage = NSLocalizedString(
                "de.cyface.error.RegistrationError.unexpectedServerError",
                value: "Server had an internal error and was unable to carry out your registration request. Please try again or contact support if the problem continues.",
                comment: """
Tell the user that the Cyface server encountered some unknown internal problems.
""")

            return errorMessage
        case .unexpectedStatusCode(statusCode: let statusCode):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.RegistrationError.unexpectedStatusCode",
                value: "Received unexpected status code %d from server. Is this really a Cyface server?",
                comment: """
Tell the user that the server returned a status code, which is not expected within the current protocol.
The returned status code is provided as an Int as the first parameter!
""")
            return String.localizedStringWithFormat(errorMessage, statusCode)
        }
    }
}
