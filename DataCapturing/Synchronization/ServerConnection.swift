/*
 * Copyright 2018 Cyface GmbH
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
import Alamofire
import os.log

/**
 Realizes a connection to a Cyface Collector server.

 An object of this class realizes a connection between an iOS app capturing some data and a Cyface Collector server receiving that data.
 The data is transmitted using HTTPS in chunks of one measurement.
 The transmission format is compressed Cyface binary format.
 The cyface binary format is created by a `CyfaceBinaryFormatSerializer`.

 This implementation follows code published here: https://gist.github.com/toddhopkinson/60cae9e48e845ce02bcf526f388cfa63

 - Author: Klemens Muthmann
 - Version: 3.0.0
 - Since: 1.0.0
 */
public class ServerConnection {

    // MARK: - Properties

    /// The logger used for objects of this class.
    private static let osLog = OSLog(subsystem: "de.cyface", category: "ServerConnection")

    /// An `URL` used to upload data to. There should be a server available at that location.
    public var apiURL: URL
    /// A connection to the persistence layer containing the data to transfer to the server.
    private let persistenceLayer: PersistenceLayer
    /// A handler for network sessions. This is especially useful to realize background data transfer sessions.
    private let networking = Networking(with: "de.cyface")
    /// An object used to authenticate this app with a Cyface Collector server.
    private let authenticator: Authenticator
    /**
     A name that tells the system which kind of iOS device this is.
     */
    private var modelIdentifier: String {
        if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] { return simulatorModelIdentifier }
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
    }

    /**
     A globally unique identifier of this device. This is used to separate data transmitted by one device from data transmitted by another one on the server side. An installation identifier is not device specific for technical and data protection reasons it is recreated every time the app is reinstalled.
    */
    var installationIdentifier: String {
        if let applicationIdentifier = UserDefaults.standard.string(forKey: "de.cyface.identifier") {
            return applicationIdentifier
        } else {
            let applicationIdentifier = UUID.init().uuidString
            UserDefaults.standard.set(applicationIdentifier, forKey: "de.cyface.identifier")
            return applicationIdentifier
        }
    }

    // MARK: - Initializers

    /**
     Creates a new server connection to a certain endpoint, loading data from the provided `persistenceLayer`.

     - Parameters:
     - url: The URL endpoint to upload data to.
     - persistenceLayer: The layer used to load the data to upload from.
     - authenticator: An object used to authenticate this app with a Cyface Collector server.
     */
    public required init(apiURL url: URL, persistenceLayer: PersistenceLayer, authenticator: Authenticator) {
        self.apiURL = url
        self.persistenceLayer = persistenceLayer
        self.authenticator = authenticator
    }

    // MARK: - Methods

    /**
     Synchronizes the provided `measurement` with a remote server and calls either a `success` or `failure` handler when finished.

     - Parameters:
     - measurement: The measurement to synchronize.
     - success: The handler to call, when synchronization has succeeded. This handler is provided with the synchronized `MeasurementEntity`.
     - failure: The handler to call, when the synchronization has failed. This handler provides an error status. The error contains the reason of the failure. The `MeasurementEntity` is the same as the one provided as parameter to this method.
     */
    public func sync(measurement: MeasurementEntity, onSuccess success: @escaping ((MeasurementEntity) -> Void) = {_ in }, onFailure failure: @escaping ((MeasurementEntity, Error) -> Void) = {_, _ in }) {

        authenticator.authenticate(onSuccess: {jwtToken in
            self.onAuthenticated(token: jwtToken, measurement: measurement, onSuccess: success, onFailure: failure)
        }, onFailure: { error in
            failure(measurement, error)
        })

    }

    /**
     The handler called after this app has successfully authenticated with a Cyface Collector server.

     - Parameters:
     - token: The Java Web Token returned by the authentication process
     - measurement: The measurement to transmit.
     - onSuccess: Called after successful data transmission with information about which measurement was transmitted.
     - onFailure: Called after a failed data transmission with information about which measurement failed and the error.
     */
    func onAuthenticated(token: String, measurement: MeasurementEntity, onSuccess: @escaping (MeasurementEntity) -> Void, onFailure: @escaping (MeasurementEntity, Error) -> Void) {
        let url = apiURL.appendingPathComponent("measurements")
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "Content-type": "multipart/form-data"
        ]

        let encode: ((MultipartFormData) -> Void) = {data in
            do {
                try self.create(request: data, forMeasurement: measurement, onFailure: onFailure)
            } catch {
                onFailure(measurement, error)
            }
        }
        networking.backgroundSessionManager.upload(multipartFormData: encode, usingThreshold: SessionManager.multipartFormDataEncodingMemoryThreshold, to: url, method: .post, headers: headers, encodingCompletion: {encodingResult in
            do {
                try self.onEncodingComplete(forMeasurement: measurement, withResult: encodingResult, onSuccess: onSuccess, onFailure: onFailure)
            } catch {
                onFailure(measurement, error)
            }
        })
    }

    /**
     Create a MultiPart/FormData request to transmit a measurement to a Cyface Collector server.

     - Parameters:
     - request: The request to fill with data.
     - forMeasurement: The measurement to transmit.
     - onFailure: A failure handler called with information about the failed measurement and the error, if request creation was not successful
     - Throws: If serializing the data to transmit was not successful.
 */
    func create(request: MultipartFormData, forMeasurement measurement: MeasurementEntity, onFailure failure: @escaping ((MeasurementEntity, Error) -> Void)) throws {
        guard let deviceIdData = installationIdentifier.data(using: String.Encoding.utf8) else {
            throw ServerConnectionError.missingInstallationIdentifier
        }
        guard let measurementIdData = String(measurement.identifier).data(using: String.Encoding.utf8) else {
            throw ServerConnectionError.missingMeasurementIdentifier
        }
        guard let deviceTypeData = modelIdentifier.data(using: String.Encoding.utf8) else {
            throw ServerConnectionError.missingDeviceType
        }

        request.append(deviceIdData, withName: "deviceId")
        request.append(measurementIdData, withName: "measurementId")
        request.append(deviceTypeData, withName: "deviceType")
        request.append("iOS \(UIDevice.current.systemVersion)".data(using: String.Encoding.utf8)!, withName: "osVersion")

        // Load and serialize measurement synchronously.
        let loadMeasurementGroup = DispatchGroup()
        loadMeasurementGroup.enter()
        persistenceLayer.load(measurementIdentifiedBy: measurement.identifier) { measurementModel in
            defer {loadMeasurementGroup.leave()}
            do {
                let payloadUrl = try self.write(measurementModel)
                request.append(payloadUrl, withName: "fileToUpload", fileName: "\(self.installationIdentifier)_\(measurement.identifier).cyf", mimeType: "application/octet-stream")
            } catch {
                failure(measurement, error)
            }
        }

        guard loadMeasurementGroup.wait(timeout: DispatchTime.now() + .seconds(120)) == DispatchTimeoutResult.success else {
            throw ServerConnectionError.serializationTimeout
        }
    }

    /**
     Called by Alamofire when encoding the request by Alamofire was finished.
     Starts the actual data transmission if encoding was successful.

     - Parameters:
     - forMeasurement: The measurement that was encoded into a transmission request
     - withResult: The encoded measurement.
     - onSuccess: Called if data transmission was successful. Gets the transmitted measurement as a parameter.
     - onFailure: Called if data transmission failed for some reason. Gets the transmitted measurement and information about the error.
    */
    func onEncodingComplete(forMeasurement measurement: MeasurementEntity, withResult result: SessionManager.MultipartFormDataEncodingResult, onSuccess success: @escaping ((MeasurementEntity) -> Void), onFailure failure: @escaping ((MeasurementEntity, Error) -> Void)) throws {
        switch result {
        case .success(let upload, _, _):
            // Two status codes are acceptable. A 201 is a successful upload, while a 409 is a conflict. In both cases the measurement should be marked as uploaded successfully.
            upload.validate(statusCode: [201, 409]).responseString { response in
                do {
                    try self.onResponseReady(forMeasurement: measurement, onSuccess: success, response)
                } catch {
                    failure(measurement, error)
                }
            }
        case .failure(let error):
            throw error
        }
    }

    /**
     A handler for the result from a data transmission call.

     - Parameters:
     - forMeasurement: The measurement that was transmitted.
     - onSuccess: Called with information about the transmitted measurement if the response indicates success.
     - response: The HTTP response received.
     - Throws: If the response was not successful.
 */
    func onResponseReady(forMeasurement measurement: MeasurementEntity, onSuccess success: ((MeasurementEntity) -> Void), _ response: DataResponse<String>) throws {
        switch response.result {
        case .success:
            success(measurement)
        case .failure(let error):
            throw error
        }
    }

    /**
     Write the provided `measurement` to a file for background synchronization

     - Parameter measurement: The measurement to serialize as a file.
     - Returns: The url of the file containing the measurement data.
     */
    private func write(_ measurement: MeasurementMO) throws -> URL {
        let measurementFile = MeasurementFile()
        return try measurementFile.write(serializable: measurement, to: measurement.identifier)
    }
}

/**
 A struct encapsulating errors used by this server connection to communicate to all the error handlers.
 ````
 case authenticationNotSuccessful
 case notAuthenticated
 case serializationTimeout
 case missingInstallationIdentifier
 case missingMeasurementIdentifier
 case missingDeviceType
 case deviceNotRegistered
 case invalidResponse
 case unexpectedError
 ````

 - Author: Klemens Muthmann
 - Version: 3.0.0
 - Since: 1.0.0
 */
public enum ServerConnectionError: Error {
    case authenticationNotSuccessful
    /// Error occuring if this client tried to communicate with the server without proper authentication.
    case notAuthenticated
    /// If data serialization for upload took too long.
    case serializationTimeout
    /// Thrown if no installation identifier is available.
    case missingInstallationIdentifier
    /// Thrown if the measurement was not persistent and thus has not identifier
    case missingMeasurementIdentifier
    /// Thrown if no device type was available from the system.
    case missingDeviceType
    /// Thrown if the response was not parseable.
    case invalidResponse
    /// Used for all unexpected errors, that should not occur during normal operation.
    case unexpectedError
}