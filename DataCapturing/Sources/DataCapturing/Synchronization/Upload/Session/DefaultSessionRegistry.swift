/*
 * Copyright 2024 Cyface GmbH
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
 - Since: 12.0.0
 */
public struct DefaultSessionRegistry: SessionRegistry {
    // MARK: - Properties
    /// A mapping from the measurement identifier to the REST resource that session is available at.
    var openSessions = [UInt64: any Upload]()
    /// Event protocols for the currently open sessions.
    var protocols = [UInt64: [RequestType]]()

    // MARK: - Initializers
    public init() {
        // Nothing to do here.
    }

    // MARK: - Methods
    public mutating func get(measurement: FinishedMeasurement) throws -> (any Upload)? {
        return openSessions[measurement.identifier]
    }
    
    /// Register a `session`for the provided `Measurement`
    /// - Parameter upload: The ``Upload`` to register this session for.
    /// - Returns: The universal unique identifier that session has been stored under
    public mutating func register(upload: any Upload) {
        openSessions[upload.measurement.identifier] = upload
    }
    public mutating func remove(upload: any Upload) {
        openSessions.removeValue(forKey: upload.measurement.identifier)
        protocols.removeValue(forKey: upload.measurement.identifier)
    }

    public mutating func record(upload: any Upload, _ requestType: RequestType, httpStatusCode: Int16, message: String, time: Date) throws {
        if protocols.index(forKey: upload.measurement.identifier)  != nil {
            protocols[upload.measurement.identifier]?.append(requestType)
        } else {
            protocols[upload.measurement.identifier] = [requestType]
        }
    }

    public mutating func record(upload: any Upload, _ requestType: RequestType, httpStatusCode: Int16, error: any Error) throws {
        try record(upload: upload, requestType, httpStatusCode: httpStatusCode, message: error.localizedDescription, time: Date.now)
    }
}

