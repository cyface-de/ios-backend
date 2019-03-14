/*
 * Copyright 2018 Cyface GmbH
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

/**
 A wrapper class for accessing the network stack

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 2.0.0
 */
class Networking {

    // MARK: - Properties

    static let sharedInstance = Networking(with: "de.cyface")
    /// The Alamofire session manager used to transmit data to and receive responses from a Cyface server.
    var sessionManager: Alamofire.SessionManager
    /// An Alamofire session manaager used for background data transmission.
    var backgroundSessionManager: Alamofire.SessionManager

    // MARK: - Initializers

    /**
     Creates a completely initialized object of this class.

     - Parameter identifier: The background session identifier. Using the same identifier retrieves your previous session after app shutdown.
    */
    private init(with identifier: String) {
        // Remove Accept-Encoding from the default headers.
        var defaultHeaders = Alamofire.SessionManager.defaultHTTPHeaders
        defaultHeaders.removeValue(forKey: "Accept-Encoding")

        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = defaultHeaders

        self.sessionManager = Alamofire.SessionManager(configuration: configuration)

        let sessionConfiguration = URLSessionConfiguration.background(withIdentifier: identifier)
        sessionConfiguration.isDiscretionary = true // Let the system decide when it is convenient.

        self.backgroundSessionManager = Alamofire.SessionManager(configuration: sessionConfiguration)
    }
}
