//
//  RFRError.swift
//  RFR
//
//  Created by Klemens Muthmann on 14.03.23.
//

import Foundation

enum RFRError: Error {
    case initializationFailed(cause: Error)
    case invalidUrl(url: String)
    case missingAuthenticator
    case unableToLoadMeasurement(measurement: Measurement)
    case missingVoucher
    case missingAuthenticationBody
    case missingCredentials
    case missingAuthenticatorConfiguration
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
        }
    }
}
