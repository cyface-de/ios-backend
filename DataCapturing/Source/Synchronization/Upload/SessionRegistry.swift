//
//  SessionRegistry.swift
//  DataCapturing
//
//  Created by Klemens Muthmann on 30.03.22.
//

import Foundation

/**
Stores the open sessions, this app knows about.

This implementation stores sessions in memory and allows continuation as long as the app was not terminated.

- author: Klemens Muthmann
 */
struct SessionRegistry {
    /// A mapping from the measurement identifier to the REST resource that session is available at.
    var openSessions = [UInt64: String]()

    /// Provide the session for the `Measurement` or `nil` if no open session is available.
    func session(for measurement: Upload) -> String? {
        return openSessions[measurement.identifier]
    }

    /// Register a `session`for the provided `Measurement`
    /// - Parameter session: The complete REST URL to the session.
    mutating func register(session: String, measurement: Upload) {
        openSessions[measurement.identifier] = session
    }
}
