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
import Alamofire
import os.log

/**
 An authenticator using a combination of `username` and `password` to authenticate against a Cyface data collector server.

 After creation of an instance of this class you need to provide a `username` and a `password`, before calling `authenticate`()`.
 If no `username` or `password` is available the function will call its failure handler with the `ServerConnectionError.Category.notAuthenticated`.

 - Author: Klemens Muthmann
 - Version: 2.0.3
 - Since: 2.0.0
 */
public class CredentialsAuthenticator: Authenticator {

    // MARK: - Properties

    /// The logger used for objects of this class.
    private static let log = OSLog(subsystem: "CredentialsAuthenticator", category: "de.cyface")
    /// The username used for authentication.
    public var username: String?
    /// The password used for authentication.
    public var password: String?
    /// The location of the Cyface Collector API, used for authentication.
    public var authenticationEndpoint: URL

    // MARK: - Initializers

    /**
     Creates a new not yet authenticated `Authenticator`.
     To authenticate you need to provide a valid `username` and `password` and call `authenticate(:(String) -> Void, :(Error) -> Void)` afterwards.

     - Parameters:
        - authenticationEndpoint: The location of the Cyface Collector API, used for authentication.
     */
    public required init(authenticationEndpoint: URL) {
        self.authenticationEndpoint = authenticationEndpoint
    }

    // MARK: - Methods

    public func authenticate(onSuccess: @escaping (String) -> Void, onFailure: @escaping (Error) -> Void) {
        guard let username = username else {
            return onFailure(ServerConnection.ServerConnectionError.notAuthenticated("Missing username!"))
        }

        guard let password = password else {
            return onFailure(ServerConnection.ServerConnectionError.notAuthenticated("Missing password!"))
        }

        // Does this have the potential for some kind of injection attack?
        do {
            let jsonCredentials = try JSONSerialization.data(withJSONObject: ["username": username, "password": password])
            let url = authenticationEndpoint.appendingPathComponent("login")

            let headers: HTTPHeaders = [
                "Content-Type": "application/json",
                "Accept": "*/*"
            ]
            let request = Alamofire.upload(
                jsonCredentials,
                to: url,
                method: .post,
                headers: headers).response { response in
                guard let httpResponse = response.response else {
                    os_log("Unable to unwrap authentication response!", log: CredentialsAuthenticator.log, type: OSLogType.error)
                    return onFailure(ServerConnection.ServerConnectionError.authenticationNotSuccessful("Unable to unwrap authentication response!"))
                }

                if httpResponse.statusCode==200, let authorizationValue = httpResponse.allHeaderFields["Authorization"] as? String {
                    onSuccess(authorizationValue)
                } else {
                    onFailure(ServerConnection.ServerConnectionError.authenticationNotSuccessful("Authentication was not successful!"))
                }
            }
            request.resume()
        } catch let error {
            onFailure(error)
        }
    }
}
