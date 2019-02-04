/*
 * Copyright 2019 Cyface GmbH
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
 An authenticator using a combination of username and password to authenticate against a Cyface data collector server.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 2.0.0
 */
public class CredentialsAuthenticator: Authenticator {

    /// The logger used for objects of this class.
    private static let oslog = OSLog(subsystem: "de.cyface", category: "CredentialsAuthenticator")
    /// The username used for authentication.
    private let username: String
    /// The password used for authentication.
    private let password: String
    /// The location of the Cyface Collector API, used for authentication.
    private let authenticationEndpoint: URL

    /**
     Creates a new completely initialized but not yet authenticated `Authenticator`.

     - Parameters:
     - username: The username used for authentication.
     - password: The password used for authentication.
     - authenticationEndpoint: The location of the Cyface Collector API, used for authentication.
     */
    public required init(username: String, password: String, authenticationEndpoint: URL) {
        self.username = username
        self.password = password
        self.authenticationEndpoint = authenticationEndpoint
    }

    public func authenticate(onSuccess: @escaping (String) -> Void, onFailure: @escaping (Error) -> Void) {
        // This is hardcoded JSON. It should not fail so we may use try!
        // Does this have the potential for some kind of injection attack?
        let jsonCredentials = try! JSONSerialization.data(withJSONObject: ["username": username, "password": password])
        let url = authenticationEndpoint.appendingPathComponent("login")

        Alamofire.upload(jsonCredentials, to: url, method: .post, headers: nil).response { response in
            guard let httpResponse = response.response else {
                os_log("Unable to unwrap authentication response", log: CredentialsAuthenticator.oslog, type: OSLogType.error)
                onFailure(ServerConnectionError.authenticationNotSuccessful)
                return
            }

            if httpResponse.statusCode==200, let authorizationValue = httpResponse.allHeaderFields["Authorization"] as? String {
                onSuccess(authorizationValue)
            } else {
                onFailure(ServerConnectionError.authenticationNotSuccessful)
            }
        }
    }
}
