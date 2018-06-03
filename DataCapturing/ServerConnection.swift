//
//  ServerConnection.swift
//  DataCapturing
//
//  Created by Team Cyface on 28.02.18.
//

import Foundation

/**
 Protocol providing an upload path for measurements, via an arbitrary format.

 - Author: Klemens Muthmann
 - Version: 2.0.0
 - Since: 1.0.0
 */
public protocol ServerConnection {
    // MARK: - Initializers

    /**
     Creates a new server connection to a certain endpoint, loading data from the provided `persistenceLayer`.

     - Parameters:
        - apiURL: The URL endpoint to upload data to.
        - persistenceLayer: The layer used to load the data to upload from.
    */
    init(apiURL url: URL, persistenceLayer: PersistenceLayer)

    // MARK: - Methods

    /**
     Checks the current authentication state.

     - Returns: `true` if this client has been authenticated; `false` otherwise.
    */
    func isAuthenticated() -> Bool

    /**
     Synchronizes the provided `measurement` and calls a `handler` when finished.

     - Parameters:
        - measurement: The measurement to synchronize.
        - handler: The handler to call, when synchronizatin has finished. This handler is provided with the `MeasurementEntity` to synchronize and an error status. The error is `nil` upon successful synchronization and contains the reason of the failure otherwise. The `MeasurementEntity` should be the same as the one provided as parameter to this method.
    */
    func sync(measurement: MeasurementEntity, onFinishedCall handler: @escaping (MeasurementEntity, ServerConnectionError?) -> Void)

    /**
     Provides the upload URL endpoint.

     - Returns: The URL used to upload data to.
    */
    func getURL() -> URL
}

// TODO: This is some crazy Objective-C stuff and I do not yet understand what a `LocalizedError` is. Need to look this up some time. For now it just works.
/**
 A struct encapsulating error messages used by this server connection to communicate to all the error handlers.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 1.0.0
 */
public struct ServerConnectionError: LocalizedError {

    // MARK: - Properties

    /// The title used for this error. Usually used to group several similar errors under the same heading.
    var title: String?
    /// A detailed description of the error.
    public var errorDescription: String? { return _description }
    /// The same as `errorDescription` in this implemenation.
    public var failureReason: String? { return _description }
    /// A detailed description of the error and the thing returned by `errorDescription` and `failureReason`.
    private var _description: String

    // MARK: - Intializers

    /**
     Creates a new error with `title` and a `description`. The title may be a heading to group several similar errors.

     - Parameters:
     - title: The title used for this error. Usually used to group several similar errors under the same heading.
     - description: A detailed description of the error.
     */
    init(title: String?, description: String) {
        self.title = title ?? "Error"
        self._description = description
    }
}
