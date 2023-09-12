/*
 * Copyright 2023 Cyface GmbH
 *
 * This file is part of the Ready for Robots App.
 *
 * The Ready for Robots App is free software: you can redistribute it and/or modify
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
 Error causes processed by the Ready for Robots application.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
enum RFRError: Error {
    case initializationFailed(cause: Error)
    case invalidUrl(url: String)
    case missingAuthenticator
    case unableToLoadMeasurement(measurement: Measurement)
    case missingVoucher
    case missingAuthenticationBody
    case missingCredentials
    case missingAuthenticatorConfiguration
    case unableToAuthenticate
    case formattingFailed(number: NSNumber)
    case voucherOverviewFailed
    /// Thrown if a background upload does not provide a `HTTPURLResponse`.
    case invalidResponse
}

extension RFRError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .initializationFailed(cause: let error):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.rfrerror.initializationFailed",
                value: "Application initialization failed due to %@!",
                comment: "Tell the user, that initialization of the Ready for Robots application failed. Futher details are available from the provided cause. The cause is the one and only parameter to this error."
            )

            return String.localizedStringWithFormat(errorMessage, error.localizedDescription)
        case .invalidUrl(url: let url):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.rfrerror.invalidUrl",
                value: "Invalid URL %@!",
                comment: "Tell the user, that the URL used for contacting the Cyface server was an invalid URL. The actual value is provided as the first parameter."
            )

            return String.localizedStringWithFormat(errorMessage, url)
        case .missingAuthenticator:
            let errorMessage = NSLocalizedString(
                "de.cyface.error.rfrerror.missingAuthenticator",
                value: "Authenticator has not been assigned yet!",
                comment: "Tell the user, that there was no authenticator. This error should not occur under normal circumstances."
            )

            return errorMessage
        case .unableToLoadMeasurement(measurement: let measurement):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.rfrerror.unableToLoadMeasurement",
                value: "Unable to load measurement %@!",
                comment: "Tell the user that a measurement could not be loaded. The device wide unique identifier of the measurement is provided as the first parameter."
            )

            return String.localizedStringWithFormat(errorMessage, measurement.id)
        case .missingVoucher:
            let errorMessage = NSLocalizedString(
                "de.cyface.error.rfrerror.missingVoucher",
                value: "Unable to load your voucher",
                comment: "Explain that no valid voucher information was found for the current user."
            )

            return errorMessage
        case .missingAuthenticationBody:
            let errorMessage = NSLocalizedString(
                "de.cyface.error.rfrerror.missingAuthenticationBody",
                value: "Authentication Response contained no body data",
                comment: "Explain that the authentication request did not return a valid token."
            )

            return errorMessage
        case .missingCredentials:
            let errorMessage = NSLocalizedString(
                "de.cyface.error.rfrerror.missingCredentials",
                value: "Missing Credentials for Authentication Request. Aborting Request.",
                comment: "Explain that an authenticator needs credentials, before authentication is possible."
            )

            return errorMessage
        case .missingAuthenticatorConfiguration:
            let errorMessage = NSLocalizedString(
                "de.cyface.error.rfrerror.missingAuthenticatorConfiguration",
                value: "Authenticator configuration file was missing.",
                comment: "Explain that the configuration for the authenticator is missing. This should not happen, since this file is included as a build artifact and should always be available.")

            return errorMessage
        case .unableToAuthenticate:
            let errorMessage = NSLocalizedString(
                "de.cyface.error.rfrerror.unableToAuthenticate",
                value: "Unable to Authenticate your user account. The Authentication Server might be down or you have provided invalid credentials. Please log out and back in again.",
                comment: "The system was unable to get a valid authentication token from the server. Either the server is not available or the user used invalid Credentials."
            )

            return errorMessage
        case .formattingFailed(number: let number):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.rfrerror.formattingFailed",
                value: "Unable to format the number %@ into a valid String representation!",
                comment: "Explain to the user, that the system was unable to format a number for display on the screen. The number is given as the first argument. This should not happen and is evidence for a serious implementation bug.")

            return String.localizedStringWithFormat(errorMessage, number)
        case .voucherOverviewFailed:
            let errorMessage = NSLocalizedString(
                "de.cyface.error.rfrerror.voucherOverviewFailed",
                value: "Unable to load voucher overview.",
                comment: "Explain to the user, that the system was unable to load the voucher overview."
            )

            return errorMessage
        case .invalidResponse:
            let errorMessage = NSLocalizedString(
                "de.cyface.error.rfrerror.invalidResponse",
                value: "Unable to process response!",
                comment: "Explain to the user, that an HTTP network response returned an invalid status response. The status code is provided as the first parameter."
            )

            return errorMessage
        }
    }
}
