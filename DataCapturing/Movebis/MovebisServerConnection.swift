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
 Realizes a connection to a Movebis data capturing server.

 An object of this class realizes a connection between an iOS app capturing some data and a Movebis server receiving that data.
 The data is transmitted using HTTPS in chunks of one measurement.
 The transmission format is compressed Cyface binary format.
 The cyface binary format is created by a `CyfaceBinaryFormatSerializer`.

 This implementation follows code published here: https://gist.github.com/toddhopkinson/60cae9e48e845ce02bcf526f388cfa63

 - Author: Klemens Muthmann
 - Version: 2.0.3
 - Since: 1.0.0
 */
public class MovebisServerConnection: ServerConnection {

    /// The current JWT authentication token to use with the Movebis server.
    private var jwtAuthenticationToken: String?
    /**
     Serializer creating the Cyface binary format from a measurement.
     The output is used as payload to transmit to the server.
     */
    private lazy var serializer = CyfaceBinaryFormatSerializer()

    public var apiURL: URL
    private let persistenceLayer: PersistenceLayer
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

    public required init(apiURL url: URL, persistenceLayer: PersistenceLayer) {
        apiURL = url
        self.persistenceLayer = persistenceLayer
    }

    public func isAuthenticated() -> Bool {
        return jwtAuthenticationToken != nil
    }

    public func authenticate(withJwtToken token: String) {
        jwtAuthenticationToken = token
    }

    public func logout() {
        jwtAuthenticationToken = nil
    }

    public func sync(measurement: MeasurementEntity, onSuccess success: @escaping ((MeasurementEntity) -> Void) = {_ in }, onFailure failure: @escaping ((MeasurementEntity, Error) -> Void) = {_, _ in }) {
        let url = apiURL.appendingPathComponent("measurements")

        guard isAuthenticated(), let jwtAuthenticationToken = jwtAuthenticationToken else {
            failure(measurement, ServerConnectionError.notAuthenticated)
            return
        }

        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(jwtAuthenticationToken)",
            "Content-type": "multipart/form-data"
        ]

        let encode: ((MultipartFormData) -> Void) = {data in
            do {
                try self.create(request: data, forMeasurement: measurement, onFailure: failure)
            } catch {
                failure(measurement, error)
            }
        }
        Networking.sharedInstance.backgroundSessionManager.upload(multipartFormData: encode, usingThreshold: SessionManager.multipartFormDataEncodingMemoryThreshold, to: url, method: .post, headers: headers, encodingCompletion: {encodingResult in
            do {
                try self.onEncodingComplete(forMeasurement: measurement, withResult: encodingResult, onSuccess: success, onFailure: failure)
            } catch {
                failure(measurement, error)
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

class Networking {
    static let sharedInstance = Networking()
    public var sessionManager: Alamofire.SessionManager
    public var backgroundSessionManager: Alamofire.SessionManager

    private init() {
        self.sessionManager = Alamofire.SessionManager(configuration: URLSessionConfiguration.default)

        // TODO: - Change the identifier used for background uploads
        let sessionConfiguration = URLSessionConfiguration.background(withIdentifier: "org.movebis")
        // TODO: - Remove wifi check. It is not necessary if this property is set to true.
        sessionConfiguration.isDiscretionary = true // Let the system decide when it is convenient.

        self.backgroundSessionManager = Alamofire.SessionManager(configuration: sessionConfiguration)
    }
}
