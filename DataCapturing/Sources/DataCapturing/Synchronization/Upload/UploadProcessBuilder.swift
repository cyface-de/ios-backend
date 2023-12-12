//
//  File.swift
//  
//
//  Created by Klemens Muthmann on 21.11.23.
//

import Foundation

public protocol UploadProcessBuilder {
    func build() -> UploadProcess
}

public class DefaultUploadProcessBuilder: UploadProcessBuilder {
    /// The endpoint of a Cyface Data Collector compatible service to upload data to.
    public let apiEndpoint: URL
    /// A registry for running and resumable upload sessions.
    let sessionRegistry: SessionRegistry

    public init(apiEndpoint: URL, sessionRegistry: SessionRegistry) {
        self.apiEndpoint = apiEndpoint
        self.sessionRegistry = sessionRegistry
    }

    public func build() -> UploadProcess {
        return DefaultUploadProcess(apiUrl: apiEndpoint, sessionRegistry: sessionRegistry)
    }
}
