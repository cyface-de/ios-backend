//
//  MovebisServerConnection.swift
//  DataCapturing
//
//  Created by Team Cyface on 23.02.18.
//

import Foundation
import Alamofire
import os.log

/**
 Realizes a connection to a data capturing server.

 An object of this class realizes a connection between an iOS app capturing some data and a Movebis server receiving that data.
 The data is transmitted using HTTPS in chunks of one measurement.
 The transmission format is compressed Cyface binary format.
 The cyface binary format is created by a `CyfaceBinaryFormatSerializer`.

 This implementation follows code published here: https://gist.github.com/toddhopkinson/60cae9e48e845ce02bcf526f388cfa63

 - Author: Klemens Muthmann
 - Version: 2.0.3
 - Since: 1.0.0
 */
public class ServerConnection {

    // MARK: - Properties

    private static let osLog = OSLog(subsystem: "de.cyface", category: "ServerConnection")

    /// A `URL` used to upload data to. There should be a server available at that location.
    public var apiURL: URL
    private let persistenceLayer: PersistenceLayer
    private let networking = Networking(with: "de.cyface")
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

        authenticator.authenticate(onSuccess: {
            jwtToken in
            self.onAuthenticated(token: jwtToken, measurement: measurement, onSuccess: success, onFailure: failure)
        }, onFailure: { error in
            failure(measurement,error)
        })


    }

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
            do {
                let payloadUrl = try self.write(measurementModel)
                //let payload = try self.serializer.serializeCompressed(measurement)
                request.append(payloadUrl, withName: "fileToUpload", fileName: "\(self.installationIdentifier)_\(measurement.identifier).cyf", mimeType: "application/octet-stream")
                loadMeasurementGroup.leave()
            } catch {
                failure(measurement, error)
            }
        }

        guard loadMeasurementGroup.wait(timeout: DispatchTime.now() + .seconds(120)) == DispatchTimeoutResult.success else {
            throw ServerConnectionError.serializationTimeout
        }
    }

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
