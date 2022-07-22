//
//  RegistrationRequest.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 21.07.22.
//

import Foundation

struct RegistrationRequest {

    let url: URL

    func request(username: String, password: String, validationToken: String) async throws {

        let body = ["email" : username, "password": password, "captcha": validationToken]

        do {
            var request = try URLRequest(url: url, method: .post)
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
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
