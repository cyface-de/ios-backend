/*
 * Copyright 2023-2024 Cyface GmbH
 *
 * This file is part of the Ready for Robots App.
 *
 * The Ready for Robots App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Ready for Robots App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Ready for Robots App. If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation

/**
 Error causes processed by the Ready for Robots application.

 - Author: Klemens Muthmann
 - Version: 2.0.0
 - Since: 3.1.2
 */
enum RFRError: Error {
    /// If application initialisation failed for `cause` reason.
    case initializationFailed(cause: Error)
    /// If some parsed URL was invalid. Should not happen, since all URLs are currently hard coded.
    case invalidUrl(url: String)
    /// If no authenticator was available to authenticate with the keycloak identity provider.
    case missingAuthenticator
    /// If the data store stack was unable to retrieve a ``Measurement``
    case unableToLoadMeasurement(measurement: Measurement)
    /// If no voucher could be loaded but should be available.
    case missingVoucher
    /// If the body from an authentication request was not available for parsing.
    case missingAuthenticationBody
    /// If no credentials have been provided for an auth request.
    case missingCredentials
    /// If the ``Authenticator`` could not be created because no configuration was available.
    case missingAuthenticatorConfiguration
    /// If a number could not be formatted for the current localization.
    case formattingFailed(number: NSNumber)
    /// If communicating with the voucher server failed and thus no overview can and should be shown.
    case voucherOverviewFailed
    /// Thrown if a background upload does not provide a `HTTPURLResponse`.
    case invalidResponse
}

extension RFRError: LocalizedError {
    /// Localizable description of the error, containing information for translation and a message for the user to act on.
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
                comment: "Explain that the configuration for the authenticator is missing. This should not happen, since this file is included as a build artifact and should always be available."
            )

            return errorMessage

        case .formattingFailed(number: let number):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.rfrerror.formattingFailed",
                value: "Unable to format the number %@ into a valid String representation!",
                comment: "Explain to the user, that the system was unable to format a number for display on the screen. The number is given as the first argument. This should not happen and is evidence for a serious implementation bug."
            )

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

extension RFRError: Hashable {
    static func == (lhs: RFRError, rhs: RFRError) -> Bool {
        switch (lhs, rhs) {
        case (.initializationFailed(let l), .initializationFailed(let r)):
            return l.localizedDescription == r.localizedDescription
        case (.invalidUrl(let l), .invalidUrl(let r)):
            return l == r
        case (.missingAuthenticator, .missingAuthenticator):
            return true
        case (.unableToLoadMeasurement(let l), .unableToLoadMeasurement(let r)):
            return l == r
        case (.missingVoucher, .missingVoucher):
            return true
        case (.missingAuthenticationBody, .missingAuthenticationBody):
            return true
        case (.missingCredentials, .missingCredentials):
            return true
        case (.missingAuthenticatorConfiguration, .missingAuthenticatorConfiguration):
            return true
        case (.formattingFailed(number: let l), .formattingFailed(number: let r)):
            return l == r
        case (.voucherOverviewFailed, .voucherOverviewFailed):
            return true
        case (.invalidResponse, .invalidResponse):
            return true
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .initializationFailed(cause: let error):
            hasher.combine(0)
            hasher.combine(error.localizedDescription)
        case .invalidUrl(url: let url):
            hasher.combine(1)
            hasher.combine(url)
        case .missingAuthenticator:
            hasher.combine(2)
        case .unableToLoadMeasurement(measurement: let measurement):
            hasher.combine(3)
            hasher.combine(measurement)
        case .missingVoucher:
            hasher.combine(4)
        case .missingAuthenticationBody:
            hasher.combine(5)
        case .missingCredentials:
            hasher.combine(6)
        case .missingAuthenticatorConfiguration:
            hasher.combine(7)
        case .formattingFailed(number: let number):
            hasher.combine(9)
            hasher.combine(number)
        case .voucherOverviewFailed:
            hasher.combine(10)
        case .invalidResponse:
            hasher.combine(11)
        }
    }
}
