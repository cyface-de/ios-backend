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
import DataCapturing
import os.log

/// A view model used by the ``LoginView`` to represent that views current state.
///
/// - author: Klemens Muthmann
/// - version: 1.0.0
/// - since: 4.0.0
class LoginViewModel: ObservableObject {
    /// The username entered into the login text field.
    @Published var username: String {
        didSet {
            settings.username = username
        }
    }
    /// The password entered into the password secure text field.
    @Published var password: String {
        didSet {
            settings.password = password
        }
    }
    /// The authenticator to use to authenticate with a Cyface Server.
    ///
    /// This authenticator should also be used by future requests to the Cyface Server, such as upload requests.
    @Published var authenticator: CredentialsAuthenticator?

    /// The application settings, some of which are changeable via the devices settings app.
    let settings: Settings
    /// The os log to log infomration to the device console.
    let log = OSLog(subsystem: "Credentials", category: "de.cyface")

    /// Create a new instance of this class, and provide a connection to the system settings.
    init(settings: Settings) {
        self.settings = settings
        self.username = settings.username ?? ""
        self.password = settings.password ?? ""

        if let authenticatedServerURL = settings.authenticatedServerUrl  {
            if authenticatedServerURL == settings.serverUrl {
                do {
                    self.authenticator = try createAuthenticator()
                } catch {
                    os_log(.error, log: log, "Unable to create Authenticator for authenticated user %{PUBLIC}@ on URL %{PUBLIC}@", username, authenticatedServerURL)
                }
            }
        }
        self.settings.add(serverUrlChangedListener: self)
    }

    /// Carry out the login of a user to the Cyface Server
    ///
    /// - Parameters:
    ///   - onSuccess: Callback called if the login was successful.
    ///   - onFailure: Callback called if the login failed.
    func login(onSuccess: @escaping ()->(), onFailure: @escaping (Error) -> Void) throws {
        let authenticator = try createAuthenticator()
        authenticator.authenticate(onSuccess: { [weak self] _ in
            self?.settings.authenticatedServerUrl = authenticator.authenticationEndpoint.absoluteString
            self?.authenticator = authenticator
            onSuccess()
        }, onFailure: onFailure)
    }

    /// Create the authenticator for the login to the Cyface Server.
    ///
    /// This authenticator should also be used by future requests to the Cyface Server, such as upload requests.
    /// - Returns: An initialized authenticator with the current values from the login form.
    private func createAuthenticator() throws -> CredentialsAuthenticator {
        guard let url = settings.serverUrl else {
            throw ViewError.noServerURL
        }

        guard let parsedURL = URL(string: url) else {
            throw ViewError.serverURLUnparseable(value: url)
        }

        let authenticator = CyfaceAuthenticator(authenticationEndpoint: parsedURL)
        authenticator.username = username
        authenticator.password = password

        return authenticator
    }
}

extension LoginViewModel: ServerUrlChangedListener {
    func to(validURL: URL) {
        authenticator = nil
    }

    func to(invalidURL: String?) {
        authenticator = nil
    }
}
