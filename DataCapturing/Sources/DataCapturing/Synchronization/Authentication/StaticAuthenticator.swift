/*
 * Copyright 2019 - 2022 Cyface GmbH
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
 A `StaticAuthenticator` always does authentication using the same Java Web Token (JWT).
 This token is provided as a fixed value and never changes.
 The creator of an object of this class needs to make sure, that the token is valid.

 This means that this authenticator does no validation and no network communication.
 It always assumes to have a valid token.
 If this is not the case, API calls based on this authenticator are going to fail!

 - Author: Klemens Muthmann
 - Version: 1.2.0
 - Since: 2.0.0
 */
public class StaticAuthenticator: Authenticator {
    // MARK: - Properties

    /// The token used for authentication.
    public var jwtToken: String?

    // MARK: - Initializers

    /// Default constructor needs to be publicly exposed to be able to create it.
    public init() {
        // Nothing to do here
    }

    // MARK: - Methods

    private func authenticate(onSuccess: (String) -> Void, onFailure: (Error) -> Void) {
        if let jwtToken = jwtToken {
            if jwtToken.isEmpty {
                onFailure(ServerConnectionError.notAuthenticated("Provided JWT token was empty."))
            }
            onSuccess(jwtToken)
        } else {
            onFailure(ServerConnectionError.notAuthenticated("No JWT token provided for authentication."))
        }
    }

    public func authenticate() async throws -> String {
        typealias AuthenticateContinuation = CheckedContinuation<String, Error>
        return try await withCheckedThrowingContinuation { (authenticateContinuation: AuthenticateContinuation) in
            authenticate(onSuccess: { jwtToken in
                authenticateContinuation.resume(returning: jwtToken)
            }, onFailure: { error in
                authenticateContinuation.resume(throwing: error)
            })
        }
    }

    public func delete() async throws {
        throw AuthenticationError.notImplemented
    }

    public func logout() async throws {
        throw AuthenticationError.notImplemented
    }

    public func callback(url: URL) {
        // Nothing to do here.
    }
}
