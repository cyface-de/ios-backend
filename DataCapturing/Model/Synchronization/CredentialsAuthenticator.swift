//
//  CredentialsAuthenticator.swift
//  DataCapturing
//
//  Created by Team Cyface on 11.01.19.
//

import Foundation
import Alamofire
import os.log

public class CredentialsAuthenticator: Authenticator {

    private static let oslog = OSLog(subsystem: "de.cyface", category: "CredentialsAuthenticator")
    private let username: String
    private let password: String
    private let authenticationEndpoint: URL

    public required init(username: String, password: String, authenticationEndpoint: URL) {
        self.username = username
        self.password = password
        self.authenticationEndpoint = authenticationEndpoint
    }

    public func authenticate(onSuccess: @escaping (String) -> Void, onFailure: @escaping (Error) -> Void) {
        // This is hardcoded JSON. It should not fail so we may use try!
        // Does this have the potential for some kind of injection attack?
        let jsonCredentials = try! JSONSerialization.data(withJSONObject: ["username":username,"password":password])
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
