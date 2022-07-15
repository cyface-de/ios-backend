//
//  ViewError.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 13.07.22.
//

import Foundation

enum ViewError {
    case noServerURL
    case serverURLUnparseable(value: String)
    case noAuthenticatedServerURL
    case authenticatedServerURLUnparseable(value: String)
    case missingAuthenticator
}

extension ViewError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noServerURL:
            let errorMessage =  NSLocalizedString(
                "de.cyface.error.LoginError.noServerURL",
                value: "Server URL in your phones settings was nil!",
                comment: """
Tell the user that he/she has no Server URL in his/her Cyface App settings and that he/she can enter one using the iOS Settings application.
""")
            return errorMessage
        case .serverURLUnparseable(let value):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.LoginError.serverURLUnparseable",
                value: "Server URL %@ entered in your phones settings is not parseable as a URL!",
                comment: """
Tell the user that he/she entered an unparseable URL into the Cyface settings of his/her iOS Settings application.
The actual value is the provided as the first parameter and is of type String.
""")
            return String.localizedStringWithFormat(errorMessage, value)
        case .noAuthenticatedServerURL:
            let errorMessage =  NSLocalizedString(
                "de.cyface.error.LoginError.noAuthenticatedServerURL",
                value: "The authenticated server URL was nil!",
                comment: """
Tell the user that the URL for the authenticated server was nil!
""")
            return errorMessage
        case .authenticatedServerURLUnparseable(value: let value):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.LoginError.authenticatedServerURLUnparseable",
                value: "The server URL %@ at which the current user was authenticated is not parseable!",
                comment: """
Tell the user that the authenticated server URL is not parseable as a URL for some reason.
The actual value is the provided as the first parameter and is of type String.
""")
            return String.localizedStringWithFormat(errorMessage, value)
        case .missingAuthenticator:
            let errorMessage =  NSLocalizedString(
                "de.cyface.error.LoginError.missingAuthenticator",
                value: "No authenticator was provided to use in the application!",
                comment: """
Tell the user that something went wrong when loading the authenticator that is created after a login was successful.
""")
            return errorMessage
        }
    }
}
