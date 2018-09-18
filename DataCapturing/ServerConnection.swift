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
 - Version: 3.0.0
 - Since: 1.0.0
 */
public protocol ServerConnection {
    // MARK: - Properties
    /// A `URL` used to upload data to. There should be a server available at that location.
    var apiURL: URL { get }

    // MARK: - Initializers

    /**
     Creates a new server connection to a certain endpoint, loading data from the provided `persistenceLayer`.

     - Parameters:
     - url: The URL endpoint to upload data to.
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
     Synchronizes the provided `measurement` with a remote server and calls either a `success` or `failure` handler when finished.

     - Parameters:
     - measurement: The measurement to synchronize.
     - success: The handler to call, when synchronization has succeeded. This handler is provided with the synchronized `MeasurementEntity`.
     - failure: The handler to call, when the synchronization has failed. This handler provides an error status. The error contains the reason of the failure. The `MeasurementEntity` is the same as the one provided as parameter to this method.
     */
    func sync(measurement: MeasurementEntity, onSuccess success: @escaping ((MeasurementEntity) -> Void), onFailure failure: @escaping ((MeasurementEntity, Error) -> Void))
}

// TODO: This is some crazy Objective-C stuff and I do not yet understand what a `LocalizedError` is. Need to look this up some time. For now it just works.
/**
 A struct encapsulating errors used by this server connection to communicate to all the error handlers.
 ````
 case notAuthenticated
 ````

 - Author: Klemens Muthmann
 - Version: 2.0.0
 - Since: 1.0.0
 */
public enum ServerConnectionError: Error {
    case authenticationNotSuccessful
    /// Error occuring if this client tried to communicate with the server without proper authentication.
    case notAuthenticated
    /// If data serialization for upload took too long.
    case serializationTimeout
    case missingInstallationIdentifier
    case missingMeasurementIdentifier
    case missingDeviceType
    case deviceNotRegistered
    case invalidResponse
    /// Used for all unexpected errors, that should not occur during normal operation.
    case unexpectedError
}
