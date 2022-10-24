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

/// Errors produced by the Cyface App.
///
/// These errors are the ones not already present in the Cyface data capturing service.
///
/// - author: Klemens Muthmann
/// - version: 1.0.0
/// - since: 4.0.0
enum ViewError {
    /// Thrown if no server URL is available via the applications settings.
    case noServerURL
    /// Thrown if the current server URL in the applications settings is not parseable as a URL.
    case serverURLUnparseable(value: String)
    /// Thrown if there is no authenticated server URL in the applications settings, while there was supposed to be one. Usually this is after a successful authentication.
    case noAuthenticatedServerURL
    /// Thrown if the currently authenticated server URL in the applications settings is not parseable.
    case authenticatedServerURLUnparseable(value: String)
    /// Thrown if there was no authenticator, even though authentication was supposedly successful. If this occurs something is wrong in the order of the views. It should only happen if core app functionality like data synchronization happens without appropriate credentials avaialble. This means either the login screen was bypassed or the existing credentials have been deleted in the meantime.
    case missingAuthenticator
    /// Thrown if some method was called on the `DataCapturingService`, which was not successfully started yet.
    case appBackendNotInitialized
}

extension ViewError: LocalizedError {
    /// Internationalized error description for all the `ViewError` error cases.
    var errorDescription: String? {
        switch self {
        case .noServerURL:
            let errorMessage =  NSLocalizedString(
                "de.cyface.error.ViewError.noServerURL",
                value: "Server URL in your phones settings was nil!",
                comment: """
Tell the user that he/she has no Server URL in his/her Cyface App settings and that he/she can enter one using the iOS Settings application.
""")
            return errorMessage
        case .serverURLUnparseable(let value):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.ViewError.serverURLUnparseable",
                value: "Server URL %@ entered in your phones settings is not parseable as a URL!",
                comment: """
Tell the user that he/she entered an unparseable URL into the Cyface settings of his/her iOS Settings application.
The actual value is the provided as the first parameter and is of type String.
""")
            return String.localizedStringWithFormat(errorMessage, value)
        case .noAuthenticatedServerURL:
            let errorMessage =  NSLocalizedString(
                "de.cyface.error.ViewError.noAuthenticatedServerURL",
                value: "The authenticated server URL was nil!",
                comment: """
Tell the user that the URL for the authenticated server was nil!
""")
            return errorMessage
        case .authenticatedServerURLUnparseable(value: let value):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.ViewError.authenticatedServerURLUnparseable",
                value: "The server URL %@ at which the current user was authenticated is not parseable!",
                comment: """
Tell the user that the authenticated server URL is not parseable as a URL for some reason.
The actual value is the provided as the first parameter and is of type String.
""")
            return String.localizedStringWithFormat(errorMessage, value)
        case .missingAuthenticator:
            let errorMessage =  NSLocalizedString(
                "de.cyface.error.ViewError.missingAuthenticator",
                value: "No authenticator was provided to use in the application!",
                comment: """
Tell the user that something went wrong when loading the authenticator that is created after a login was successful.
""")
            return errorMessage
        case .appBackendNotInitialized:
            let errorMessage = NSLocalizedString("de.cyface.error.ViewError.appBackendNotInitialized",
                                                 value: "Stopping since backend was not initialized!",
                                                 comment: """
Tell the user that some call to the app backend was not successful, since it was not yet initialized. Such an error marks a grave programming bug and can only be solved by fixing the current app version.
""")
            return errorMessage
        }
    }
}
