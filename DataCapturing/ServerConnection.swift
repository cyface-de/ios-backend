//
//  ServerConnection.swift
//  DataCapturing
//
//  Created by Team Cyface on 28.02.18.
//

import Foundation

public protocol ServerConnection {
    init(apiURL url: URL)

    func isAuthenticated() -> Bool

    func sync(measurement: MeasurementMO, onFinish handler: @escaping (ServerConnectionError?) -> Void)
}
