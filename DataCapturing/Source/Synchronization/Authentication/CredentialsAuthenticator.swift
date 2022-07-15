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
 An authenticator using a combination of `username` and `password` to authenticate against a Cyface data collector server.

 After creation of an instance of this class you need to provide a `username` and a `password`, before calling `authenticate()`.
 If no `username` or `password` is available the function will call its failure handler with the `ServerConnectionError.Category.notAuthenticated`.

 - Author: Klemens Muthmann
 - Version: 2.0.3
 - Since: 2.0.0
 */
public protocol CredentialsAuthenticator: Authenticator {

    // MARK: - Properties

    /// The username used for authentication.
    var username: String? { get set }
    /// The password used for authentication.
    var password: String? { get set }
    /// The location of the Cyface Collector API, used for authentication.
    var authenticationEndpoint: URL { get }
}
