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
 A ``UploadProcessBuilder`` for the ``DefaultUploadProcess``

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 12.0.0
 */
public struct DefaultUploadProcessBuilder {
    // MARK: - Properties
    /// The endpoint of a Cyface Data Collector compatible service to upload data to.
    public let collectorUrl: URL
    /// A registry for running and resumable upload sessions.
    let sessionRegistry: SessionRegistry
    /// A factory to create ``Upload`` instances on execution of the created ``UploadProcess``.
    let uploadFactory: UploadFactory
    /// Authenticator to use for ``UploadProcess`` instances created by this builder.
    let authenticator: Authenticator

    // MARK: - Initializers
    public init(collectorUrl: URL, sessionRegistry: SessionRegistry, uploadFactory: UploadFactory, authenticator: Authenticator) {
        self.collectorUrl = collectorUrl
        self.sessionRegistry = sessionRegistry
        self.uploadFactory = uploadFactory
        self.authenticator = authenticator
    }
}

// MARK: - Implementation of UploadProcessBuilder
extension DefaultUploadProcessBuilder: UploadProcessBuilder {
    public func build() -> UploadProcess {
        return DefaultUploadProcess(openSessions: sessionRegistry, apiUrl: collectorUrl, uploadFactory: uploadFactory, authenticator: authenticator)
    }
}
