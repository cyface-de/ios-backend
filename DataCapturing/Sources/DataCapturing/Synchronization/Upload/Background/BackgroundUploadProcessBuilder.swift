//
//  File.swift
//  
//
//  Created by Klemens Muthmann on 27.02.24.
//

import Foundation
import UIKit

public protocol BackgroundURLSessionEventDelegate {
    func received(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void)
}

public class BackgroundUploadProcessBuilder {
    // MARK: - Attributes
    let sessionREgistry: SessionRegistry
    let collectorUrl: URL
    let uploadFactory: UploadFactory
    // TODO: Maybe put this into its own class. Has nothing really to do with building.
    var completionHandler: (() -> Void)?

    // MARK: - Initializers
    public init(sessionRegistry: SessionRegistry, collectorUrl: URL, uploadFactory: UploadFactory) {
        self.sessionREgistry = sessionRegistry
        self.collectorUrl = collectorUrl
        self.uploadFactory = uploadFactory
    }
}

extension BackgroundUploadProcessBuilder: UploadProcessBuilder {
    public func build() -> UploadProcess {
        return BackgroundUploadProcess(
            builder: self,
            sessionRegistry: sessionREgistry,
            collectorUrl: collectorUrl, 
            uploadFactory: uploadFactory
        )
    }
}

extension BackgroundUploadProcessBuilder: BackgroundURLSessionEventDelegate {
    public func received(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        self.completionHandler = completionHandler
    }
}
