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
    /**
     The Alamofire `SessionManager`, which is used to authenticate and upload data.
     */
    private let sessionManager: SessionManager
    private let apiURL: URL
    private var onFinishHandler: ((MeasurementEntity, ServerConnectionError?) -> Void)?
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
        sessionManager = SessionManager()
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

    /**
     * Synchronizes a `measurement` with a Movebis server.
     * The Movebis server must run at the endpoint provided to the constructor of this class, as `apiUrl`.
     *
     * - Parameters:
     *     - measurement: The `MeasurementEntity` to synchronize
     *     - onFinishedCall: Callback to call as soon as transmission has finished.
     */
    public func sync(measurement: MeasurementEntity, onFinishedCall handler: @escaping (MeasurementEntity, ServerConnectionError?) -> Void) {
        let url = apiURL.appendingPathComponent("measurements")
        onFinishHandler = handler

        guard isAuthenticated(), let jwtAuthenticationToken = jwtAuthenticationToken else {
            handler(measurement, ServerConnectionError(title: "Not Authenticated", description: "MovebisServerConnection.sync(measurement:\(measurement.identifier)): No authentication information provided."))
            return
        }

        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(jwtAuthenticationToken)",
            "Content-type": "multipart/form-data"
        ]


        // TODO: - This needs to be implemented as background upload from a file!!!
        var encodingError: DataSynchronizationError?
        let encode: ((MultipartFormData) -> Void) = {data in
            do {
                try self.create(request: data, forMeasurement: measurement)
            } catch DataSynchronizationError.serializationTimeout {
                encodingError = DataSynchronizationError.serializationTimeout
            } catch {
                fatalError("MovebisServerConnection.sync(measurement: \(measurement.identifier)): Unexpected Exception during upload data encoding!")
            }
        }
        sessionManager.upload(multipartFormData: encode, usingThreshold: UInt64.init(), to: url, method: .post, headers: headers, encodingCompletion: {encodingResult in
            if encodingError != nil {
                    os_log("Aborting upload because serialization timed out!")
                } else {
                    self.onEncodingComplete(forMeasurement: measurement, withResult: encodingResult)
                }
            })
    }

    public func getURL() -> URL {
        return apiURL
    }

    func create(request: MultipartFormData, forMeasurement measurement: MeasurementEntity) throws {
        debugPrint("create")
        guard let deviceIdData = installationIdentifier.data(using: String.Encoding.utf8) else {
            fatalError("Unable to provide device identifier to upload request!")
        }
        guard let measurementIdData = String(measurement.identifier).data(using: String.Encoding.utf8) else {
            fatalError("Unable to provide measurement identifier to upload request!")
        }
        guard let deviceTypeData = modelIdentifier.data(using: String.Encoding.utf8) else {
            fatalError("Unable to provide device type to upload request!")
        }

        request.append(deviceIdData, withName: "deviceId")
        request.append(measurementIdData, withName: "measurementId")
        request.append(deviceTypeData, withName: "deviceType")
        request.append("iOS \(UIDevice.current.systemVersion)".data(using: String.Encoding.utf8)!, withName: "osVersion")

        // Load and serialize measurement synchronously.
        let loadMeasurementGroup = DispatchGroup()
        loadMeasurementGroup.enter()
        persistenceLayer.load(measurementIdentifiedBy: measurement.identifier) { measurement in
            debugPrint("loaded measurement \(measurement.identifier)")
            do {
                try self.write(measurement)
                let payload = try self.serializer.serializeCompressed(measurement)
                request.append(payload, withName: "fileToUpload", fileName: "\(self.installationIdentifier)_\(measurement.identifier).cyf", mimeType: "application/octet-stream")
                loadMeasurementGroup.leave()
            } catch {
                fatalError("Unable to serialize measurement \(measurement.identifier). Error \(error).")
            }
        }

        guard loadMeasurementGroup.wait(timeout: DispatchTime.now() + .seconds(120)) == DispatchTimeoutResult.success else {
            throw DataSynchronizationError.serializationTimeout
        }
    }

    func onEncodingComplete(forMeasurement measurement: MeasurementEntity, withResult result: SessionManager.MultipartFormDataEncodingResult) {
        debugPrint("onEncodingComplete")
        switch result {
        case .success(let upload, _, _):
            debugPrint("Uploading!")
            // Two status codes are acceptable. A 201 is a successful upload, while a 409 is a conflict. In both cases the measurement should be marked as uploaded successfully.
            upload.validate(statusCode: [201, 409]).responseString { response in
                debugPrint("Got Response")
                self.onResponseReady(forMeasurement: measurement, response)
            }
        case .failure(let error):
            debugPrint("failure")
            if let handler = onFinishHandler {
                handler(measurement, ServerConnectionError(title: "Upload error", description: "MovebisServerConnection.onEncodingComplete(\(result)): Unable to upload data \(error.localizedDescription)."))
            }
        }
    }

    func onResponseReady(forMeasurement measurement: MeasurementEntity, _ response: DataResponse<String>) {
        debugPrint("onResponseReady")
        guard let handler = onFinishHandler else {
            return
        }

        switch response.result {
        case .failure(let error):
            handler(measurement, ServerConnectionError(title: "Upload error", description: "MovebisServerConnection.onResponseReady(\(response)): Unable to upload data due to error: \(error)"))
        case .success:
            handler(measurement, nil)
        }
    }

    /**
     Write the provided `measurement` to a file for background synchronization

     - Parameter measurement: The measurement to serialize as a file.
     */
    private func write(_ measurement: MeasurementMO) throws {
        let measurementFile = MeasurementFile()
        try measurementFile.append(serializable: measurement, to: measurement.identifier)
    }
}

enum EncodingResult {
    case success
    case failure(error: DataSynchronizationError)
}
