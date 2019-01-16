//
//  StaticAuthenticator.swift
//  DataCapturing
//
//  Created by Team Cyface on 11.01.19.
//

import Foundation

class StaticAuthenticator: Authenticator {

    let jwtToken: String

    required init(jwtToken: String) {
        self.jwtToken = jwtToken
    }

    func authenticate(onSuccess: (String) -> Void, onFailure: (Error) -> Void) {
        onSuccess(jwtToken)
    }
}
