//
//  ServerConnectionError.swift
//  DataCapturing
//
//  Created by Klemens Muthmann on 30.03.22.
//

import Foundation
import Alamofire

/**
 A structure encapsulating errors used by server connections.

 - Author: Klemens Muthmann
 - Version: 5.0.0
 - Since: 1.0.0
 */
public enum ServerConnectionError: Error {
    /// If authentication was carried out but was not successful
    case authenticationNotSuccessful(String)
    /// Error occuring if this client tried to communicate with the server without proper authentication
    case notAuthenticated(String)
    /// Thrown if modality type changes are inconsistent
    case modalityError(String)
    /// Thrown if measurement events are inconsistent
    case measurementError(Int64)
    /// Thrown if some measurement metadata was not encodable as an UTF-8 String
    case dataError(String)
    case alamofireError(AFError)
    case noResponse
    case requestFailed(httpStatusCode: Int)
    case noLocation
    case invalidUploadLocation(String)
    case uploadFailed(Error)
    case preRequestFailed(Error)
    case checkResumeFailed
}
