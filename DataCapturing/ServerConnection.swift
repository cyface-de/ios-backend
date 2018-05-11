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

    func sync(measurement: MeasurementEntity, onFinishedCall handler: @escaping (MeasurementEntity, ServerConnectionError?) -> Void)

    func getURL() -> URL
}
