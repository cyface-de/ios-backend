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
 A ``UploadProcessBuilder`` creating a ``MockUploadProcess``.

 Such a builder is useful during testing and for displaying *SwiftUI* previews.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
public class MockUploadProcessBuilder: UploadProcessBuilder {
    // MARK: - Properties
    /// The endpoint for the created process, which is ignored in this case.
    let apiEndpoint: URL
    /// The ``SessionRegistry``, which is ignored for the created ``Upload`` instances.
    let sessionRegistry: SessionRegistry

    // MARK: - Initializers
    /// Create a new, fully initialized instance of this class.
    public init(apiEndpoint: URL, sessionRegistry: SessionRegistry) {
        self.apiEndpoint = apiEndpoint
        self.sessionRegistry = sessionRegistry
    }

    // MARK: - Methods
    /// Start the creation process
    public func build() -> DataCapturing.UploadProcess {
        return MockUploadProcess()
    }
}
