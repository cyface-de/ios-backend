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
import Alamofire
import os.log

/**
Implementation of a ``CredentialsAuthenticator`` as used by the Cyface apps.

 - author: Klemens Muthmann
 - version: 1.0.0
 */
public class CyfaceAuthenticator: CredentialsAuthenticator {

    // MARK: - Properties

    /// The logger used for objects of this class.
    private static let log = OSLog(subsystem: "CredentialsAuthenticator", category: "de.cyface")
    public var username: String?
    public var password: String?
    public var authenticationEndpoint: URL
    /// An Alamofire session to use for sending requests and receiving responses.
    private let session: Session

    // MARK: - Initializers

    /**
     Creates a new not yet authenticated `Authenticator`.
     To authenticate you need to provide a valid `username` and `password` and call `authenticate(:(String) -> Void, :(Error) -> Void)` afterwards.

     - Parameters:
        - authenticationEndpoint: The location of the Cyface Collector API, used for authentication.
        - session: An Alamofire session to use for sending requests and receiving responses.
     */
    public required init(authenticationEndpoint: URL, session: Session = AF) {
        self.authenticationEndpoint = authenticationEndpoint
        self.session = session
    }

    // MARK: - Methods

    public func authenticate(onSuccess: @escaping (String) -> Void, onFailure: @escaping (Error) -> Void) {
        guard let username = username else {
            return onFailure(ServerConnectionError.notAuthenticated("Missing username!"))
        }

        guard let password = password else {
            return onFailure(ServerConnectionError.notAuthenticated("Missing password!"))
        }

        // Does this have the potential for some kind of injection attack?
        do {
            let jsonCredentials = try JSONSerialization.data(withJSONObject: ["username": username, "password": password])
            let url = authenticationEndpoint.appendingPathComponent("login")

            let headers: HTTPHeaders = [
                "Content-Type": "application/json",
                "Accept": "*/*"
            ]
            let request = session.upload(
                jsonCredentials,
                to: url,
                method: .post,
                headers: headers)
            request.response { response in
                guard let httpResponse = response.response else {
                    os_log("Unable to unwrap authentication response!", log: CyfaceAuthenticator.log, type: OSLogType.error)
                    return onFailure(ServerConnectionError.authenticationNotSuccessful(username))
                }

                if httpResponse.statusCode==200, let authorizationValue = httpResponse.allHeaderFields["Authorization"] as? String {
                    onSuccess(authorizationValue)
                } else {
                    onFailure(ServerConnectionError.authenticationNotSuccessful(username))
                }
            }
            request.resume()
        } catch let error {
            onFailure(error)
        }
    }
}
