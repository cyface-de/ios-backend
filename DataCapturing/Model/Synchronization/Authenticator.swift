//
//  Authenticator.swift
//  DataCapturing
//
//  Created by Team Cyface on 11.01.19.
//

import Foundation

public protocol Authenticator {
    func authenticate(onSuccess: @escaping (String) -> Void, onFailure: @escaping (Error) -> Void)
}
