//
//  File.swift
//  DataCapturing
//
//  Created by Team Cyface on 09.10.18.
//

import Foundation
import Alamofire

/**
 A wrapper class for accessing the network stack

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 2.0.0
 */
class Networking {

    /// The Alamofire session manager used to transmit data to and receive responses from a Cyface server.
    public var sessionManager: Alamofire.SessionManager
    public var backgroundSessionManager: Alamofire.SessionManager

    init(with identifier: String) {
        // Remove Accept-Encoding from the default headers.
        var defaultHeaders = Alamofire.SessionManager.defaultHTTPHeaders
        defaultHeaders.removeValue(forKey: "Accept-Encoding")

        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = defaultHeaders

        self.sessionManager = Alamofire.SessionManager(configuration: configuration)

        let sessionConfiguration = URLSessionConfiguration.background(withIdentifier: identifier)
        // TODO: - Remove wifi check. It is not necessary if this property is set to true.
        sessionConfiguration.isDiscretionary = true // Let the system decide when it is convenient.

        self.backgroundSessionManager = Alamofire.SessionManager(configuration: sessionConfiguration)
    }
}
