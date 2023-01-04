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

/**
An `Authenticator` provides functionality to authenticate this app on a servoer for receiving the captured data.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 2.0.0
 */
public protocol Authenticator {

    /**
     Runs the authentication and calls the appropriate function `onSuccess` or `onFailure` when finished.

     - Parameters:
     - onSuccess: A closure called and supplied with the resulting authentication token, when authentication was successful.
     - onFailure: A closure called and supplied with the causing error, when authentication was not successful.
    */
    func authenticate(onSuccess: @escaping (String) -> Void, onFailure: @escaping (Error) -> Void)
}
