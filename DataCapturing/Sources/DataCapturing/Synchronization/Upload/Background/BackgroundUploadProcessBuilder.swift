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
import UIKit

/**
 Delegate receiving background URL session events.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
public protocol BackgroundURLSessionEventDelegate {
    func received(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void)
}

/**
 A builder for ``BackgroundUploadProcess`` instances. Since each upload needs its own process. This builder allows to inject the creation into objects, that are synchronizing data to a Cyface data collector service.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
public class BackgroundUploadProcessBuilder {
    // MARK: - Attributes
    let sessionRegistry: SessionRegistry
    let collectorUrl: URL
    let uploadFactory: UploadFactory
    let dataStoreStack: DataStoreStack
    let authenticator: Authenticator
    // TODO: Maybe put this into its own class. Has nothing really to do with building.
    var completionHandler: (() -> Void)?

    // MARK: - Initializers
    public init(
        sessionRegistry: SessionRegistry,
        collectorUrl: URL,
        uploadFactory: UploadFactory,
        dataStoreStack: DataStoreStack,
        authenticator: Authenticator
    ) {
        self.sessionRegistry = sessionRegistry
        self.collectorUrl = collectorUrl
        self.uploadFactory = uploadFactory
        self.dataStoreStack = dataStoreStack
        self.authenticator = authenticator
    }
}

extension BackgroundUploadProcessBuilder: UploadProcessBuilder {
    public func build() -> UploadProcess {
        return BackgroundUploadProcess(
            builder: self,
            sessionRegistry: sessionRegistry,
            collectorUrl: collectorUrl,
            uploadFactory: uploadFactory,
            dataStoreStack: dataStoreStack,
            authenticator: authenticator
        )
    }
}

extension BackgroundUploadProcessBuilder: BackgroundURLSessionEventDelegate {
    public func received(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        self.completionHandler = completionHandler
    }
}
