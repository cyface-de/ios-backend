/*
 * Copyright 2022 Cyface GmbH
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
 Stores the open sessions, this app knows about.

 This implementation stores sessions in memory and allows continuation as long as the app was not terminated.

 - author: Klemens Muthmann
 - version: 1.0.0
 */
public struct SessionRegistry {
    /// A mapping from the measurement identifier to the REST resource that session is available at.
    var openSessions = [UInt64: String]()

    /// Provide a public initializer, which is required to use this framework
    public init() {
        // Nothing to do here
    }

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
