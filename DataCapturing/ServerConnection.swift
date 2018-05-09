//
//  ServerConnection.swift
//  DataCapturing
//
//  Created by Team Cyface on 28.02.18.
//

import Foundation

public protocol ServerConnection {
    init(apiURL url: URL, persistenceLayer: PersistenceLayer)

    func isAuthenticated() -> Bool

    func sync(measurementIdentifiedBy identifier: Int64, onFinishedCall handler: @escaping (Int64, ServerConnectionError?) -> Void)

    func getURL() -> URL
}
