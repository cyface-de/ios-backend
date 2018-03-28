//
//  MovebisServerConnection.swift
//  DataCapturing
//
//  Created by Team Cyface on 23.02.18.
//

import Foundation
import Alamofire

/**
 Realizes a connection to a Movebis data capturing server.

 An object of this class realizes a connection between an iOS app capturing some data and a Movebis server receiving that data.
 The data is transmitted using HTTPS in chunks of one measurement.
 The transmission format is compressed Cyface binary format.
 The cyface binary format is created by a `CyfaceBinaryFormatSerializer`.

 - Author:
 Klemens Muthmann

 - Version:
 1.0.0

 - Since:
 1.0.0
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
    private var onFinishHandler: ((MeasurementMO, ServerConnectionError?) -> Void)?
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

    public required init(apiURL url: URL) {
        apiURL = url
        sessionManager = SessionManager()
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

    public func sync(measurement: MeasurementMO, onFinish handler: @escaping (MeasurementMO, ServerConnectionError?) -> Void) {
        let url = apiURL.appendingPathComponent("measurements")
        onFinishHandler = handler

        guard isAuthenticated(), let jwtAuthenticationToken = jwtAuthenticationToken else {
            handler(measurement, ServerConnectionError(title: "Not Authenticated", description: "MovebisServerConnection.sync(measurement:\(measurement.identifier)): Unable to sync. No authentication information provided."))
            return
        }

        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(jwtAuthenticationToken)",
            "Content-type": "multipart/form-data"
        ]

        sessionManager.upload(multipartFormData: {[unowned self] data in self.create(request: data, forMeasurement: measurement)}, usingThreshold: UInt64.init(), to: url, method: .post, headers: headers) { [unowned self] error in
            self.onEncodingComplete(forMeasurement: measurement, withResult: error)
        }
    }

    public func getURL() -> URL {
        return apiURL
    }

    func create(request: MultipartFormData, forMeasurement measurement: MeasurementMO) {
        request.append(installationIdentifier.data(using: String.Encoding.utf8)!, withName: "deviceId")
        request.append(String(measurement.identifier).data(using: String.Encoding.utf8)!, withName: "measurementId")
        request.append(modelIdentifier.data(using: String.Encoding.utf8)!, withName: "deviceType:")
        request.append("iOS \(UIDevice.current.systemVersion)".data(using: String.Encoding.utf8)!, withName: "osVersion")

        let payload = serializer.serializeCompressed(measurement)
        request.append(payload, withName: "fileToUpload", fileName: "\(installationIdentifier)_\(measurement.identifier).cyf", mimeType: "application/octet-stream")
    }

    func onEncodingComplete(forMeasurement measurement: MeasurementMO, withResult result: SessionManager.MultipartFormDataEncodingResult) {
        switch result {
        case .success(let upload, _, _):
            print("Successfully encoded upload \(upload)")
            upload.validate().responseString { response in
                self.onResponseReady(forMeasurement: measurement, response)
            }
        case .failure(let error):
            print("failure")
            if let handler = onFinishHandler {
                handler(measurement, ServerConnectionError(title: "Upload error", description: "MovebisServerConnection.onEncodingComplete(\(result)): Unable to upload data \(error.localizedDescription)."))
            }
        }
    }

    func onResponseReady(forMeasurement measurement: MeasurementMO, _ response: DataResponse<String>) {
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
}
