/*
 * Copyright 2018 - 2022 Cyface GmbH
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
import CoreData

/**
 Realizes a connection to a Cyface Collector server.

 An object of this class realizes a connection between an iOS app capturing some data and a Cyface Collector server receiving that data.
 The data is transmitted using HTTPS in chunks of one measurement.
 The transmission format is compressed Cyface binary format.
 The cyface binary format is created by a `CyfaceBinaryFormatSerializer`.

 This implementation follows code published here: https://gist.github.com/toddhopkinson/60cae9e48e845ce02bcf526f388cfa63

 - Author: Klemens Muthmann
 - Version: 8.1.0
 - Since: 1.0.0
 */
public class ServerConnection {

    // MARK: - Properties

    /// The logger used for objects of this class.
    private static let osLog = OSLog(subsystem: "ServerConnection", category: "de.cyface")
    /// An `URL` used to upload data to. There should be a server available at that location.
    public var apiURL: URL
    /// An object used to authenticate this app with a Cyface Collector server.
    public let authenticator: Authenticator
    /// A name that tells the system which kind of iOS device this is.
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

    /// The *CoreData* stack used to access the data to transfer.
    let manager: CoreDataManager

    // MARK: - Initializers

    /**
     Creates a new server connection to a certain endpoint, using the provided authentication method.

     - Parameters:
        - apiURL: The URL endpoint to upload data to.
        - authenticator: An object used to authenticate this app with a Cyface Collector server.
        - onManager: The *CoreData* stack used to load the data to transmit.
     */
    public required init(apiURL url: URL, authenticator: Authenticator, onManager manager: CoreDataManager) {
        self.apiURL = url
        self.authenticator = authenticator
        self.manager = manager
    }

    // MARK: - Methods

    /**
     Synchronizes the provided `measurement` with a remote server and calls either a `success` or `failure` handler when finished.

     - Parameters:
        - measurement: The measurement to synchronize.
        - onSuccess: The handler to call, when synchronization has succeeded. This handler is provided with the synchronized `MeasurementEntity`.
        - onFailure: The handler to call, when the synchronization has failed. This handler provides an error status. The error contains the reason of the failure. The `MeasurementEntity` is the same as the one provided as parameter to this method.
     */
    public func sync(measurement: Int64, onSuccess success: @escaping ((Int64) -> Void) = {_ in }, onFailure failure: @escaping ((Int64, Error) -> Void) = {_, _ in }) {
        os_log("Starting synchronization of measurement %{public}d with Authentication against server!", log: ServerConnection.osLog, type: .debug, measurement)
        authenticator.authenticate(onSuccess: {jwtToken in
            os_log("Authentication successful for measurement %{public}d.", log: ServerConnection.osLog, type: .debug, measurement)
            self.onAuthenticated(token: jwtToken, measurement: measurement, onSuccess: success, onFailure: failure)
        }, onFailure: { error in
            os_log("Authentication failed for measurement %{public}d.", log: ServerConnection.osLog, type: .debug, measurement)
            failure(measurement, error)
        })

    }

    /**
     The handler called after this app has successfully authenticated with a Cyface Collector server.

     - Parameters:
        - token: The Java Web Token returned by the authentication process
        - measurement: The measurement to transmit.
     // TODO: Remove those handlers, maybe?
        - onSuccess: Called after successful data transmission with information about which measurement was transmitted.
        - onFailure: Called after a failed data transmission with information about which measurement failed and the error.
     */
    func onAuthenticated(token: String, measurement: Int64, onSuccess: @escaping (Int64) -> Void, onFailure: @escaping (Int64, Error) -> Void) {
        preRequest(token: token, measurementIdentifier: measurement, onSuccess: {[weak self] uploadLocation, metaData in
            guard let self = self else {
                os_log("ServerConnection was terminated before upload of measurement %{public}@ was finished. Aborting upload!", log: ServerConnection.osLog, type: .error, measurement)
                return
            }

            try self.upload(token: token, metaData: metaData)
        }, onFailure: {error in
            onFailure(measurement, error)
        })

//        let url = apiURL.appendingPathComponent("measurements")
//        let headers: HTTPHeaders = [
//            "accept": "*/*",
//            "Authorization": "Bearer \(token)",
//            "Content-type": "multipart/form-data"
//        ]
//
//        let encode: ((MultipartFormData) -> Void) = {data in
//            os_log("Encoding!", log: ServerConnection.osLog, type: OSLogType.default)
//            do {
//                try self.create(request: data, for: measurement)
//            } catch {
//                onFailure(measurement, error)
//            }
//        }
//        os_log("Transmitting measurement to URL %{public}@!", log: ServerConnection.osLog, type: .debug, url.absoluteString)
//        Networking.sharedInstance.backgroundSessionManager.upload(
//            multipartFormData: encode,
//            usingThreshold: SessionManager.multipartFormDataEncodingMemoryThreshold,
//            to: url,
//            method: .post,
//            headers: headers,
//            encodingCompletion: {encodingResult in
//            do {
//                try self.onEncodingComplete(for: measurement, with: encodingResult, onSuccess: onSuccess, onFailure: onFailure)
//            } catch {
//                onFailure(measurement, error)
//            }
//        })
    }

    private func preRequest(token: String, measurementIdentifier: Int64, onSuccess: @escaping (URL, MetaData) -> (), onFailure: @escaping (Error) -> ()) {
        let url = apiURL.appendingPathComponent("measurements")
        let metaData = metaData(measurementIdentifier)
        let headers: HTTPHeaders = [
            "Content-Type": "application/json; charset=UTF-8",
            "Authorization": "Bearer \(token)",
            // TODO: Calculate valid upload length
            "x-upload-content-length": "100"
        ]

        AF.request(apiURL, method: .post, parameters: metaData, encoder: JSONParameterEncoder.default, headers: headers).response { [weak self] response in

            guard let response = response.response else {
                if let error = response.error {
                    onFailure(ServerConnectionError.alamofireError(error))
                } else {
                    onFailure(ServerConnectionError.noResponse)
                }
                return
            }

            let status = response.statusCode
            guard let location = response.headers["Location"] else {
                onFailure(ServerConnectionError.noLocation)
                return
            }

            if status == 200 {
                if let uploadLocation = URL(string:location){
                    onSuccess(uploadLocation, metaData)
                } else {
                    onFailure(ServerConnectionError.invalidUploadLocation(location))
                }
            } else {
                onFailure(ServerConnectionError.requestFailed(httpStatusCode: status))
            }
        }
    }

    private func metaData(_ measurementIdentifier: Int64) -> MetaData {
        // TODO: Add metadata loading from database
        return MetaData()
    }

    private func data(_ measurementIdentifier: Int64) -> Data {
        // TODO: Add data loading from database
        return Data()
    }

    private func upload(token: String, measurementIdentifier: Int64, metaData: MetaData, uploadLocation: URL, onSuccess: (Int64) -> (), onFailure: (Error)->()) throws {
        let data = data(measurementIdentifier)
        let headers: HTTPHeaders = [
            "Content-Type": "application/octet-stream",
            // TODO: This probably must be adapted on upload resume
            "Content-Length": String(data.count),
            // TODO: Add correct content range based on server values for resume
            "Content-Range": "bytes 0-\(data.count-1)/\(data.count)",
            "Authorization": "Bearer \(token)",
            "deviceId": metaData.deviceId,
            "measurementId": String(metaData.measurementId),
            "locationCount": String(metaData.locationCount),
            "startLocLat": String(metaData.startLocLat),
            "startLocLon": String(metaData.startLocLon),
            "startLocTS": String(metaData.startLocTS),
            "endLocLat": String(metaData.endLocLat),
            "endLocLon": String(metaData.endLocLon),
            "endLocTS": String(metaData.endLocTS),
            "formatVersion": "2",
            "deviceType": metaData.deviceType,
            "osVersion": metaData.osVersion,
            "appVersion": metaData.applicationVersion,
            "length": String(metaData.length),
            "modality": metaData.modality
        ]

        AF.upload(data, to: uploadLocation, method: .put, headers: headers).response { response in
            guard let response = response.response else {
                if let error = response.error {
                    onFailure(error)
                } else {
                    onFailure(ServerConnectionError.noResponse)
                }
                return
            }

            let status = response.statusCode

            if status == 200 {
                onSuccess(measurementIdentifier)
            } else {
                onFailure(ServerConnectionError.requestFailed(httpStatusCode: status))
            }
        }
    }

    /**
     Create a MultiPart/FormData request to transmit a measurement to a Cyface Collector server.

     - Parameters:
        - request: The request to fill with data
        - for: The measurement to transmit
     - Throws: `ServerConnectionError.modalityError` if the initial modality for the measurement was not set correctly. If this happens the measurement was probably not correctly created via this framework and something is seriously wrong.
     - Throws: `ServerConnectionError.dataError` if important data for the provided `measurement` is missing from the database.
     - Throws: `PersistenceError.measurementNotLoadable` if the measurement could not be retrieved from the database.
     - Throws: `FileSupportError.notReadable` If the data to transmit from the database could not be serialized.
     - Throws: Some unspecified errors from within CoreData, Some unspecified undocumented file system error if file was not accessible
     */
    func create(request: MultipartFormData, for measurement: Int64) throws {
        os_log("Creating request", log: ServerConnection.osLog, type: .default)
        // Load and serialize measurement synchronously.
        let persistenceLayer = PersistenceLayer(onManager: manager)
        let measurement = try persistenceLayer.load(measurementIdentifiedBy: measurement)
        let modalityTypeChangeEvents = try persistenceLayer.loadEvents(typed: .modalityTypeChange, forMeasurement: measurement)
        guard !modalityTypeChangeEvents.isEmpty else {
            throw ServerConnectionError.modalityError("No modality type information available!")
        }
        guard let initialModality = modalityTypeChangeEvents[0].value else {
            throw ServerConnectionError.modalityError("Invalid modality change event with no value encountered!")
        }

        try addMetaData(to: request, for: measurement, withInitialModality: initialModality)

        let measurementFileWriter = MeasurementFile()
        let measurementFileURL = try measurementFileWriter.write(serializable: measurement, to: measurement.identifier)
        let measurementFileName = "\(self.installationIdentifier)_\(measurement.identifier).ccyf"
        request.append(measurementFileURL, withName: "fileToUpload", fileName: measurementFileName, mimeType: "application/octet-stream")
    }

    /**
     Adds the required meta data from a measurement to a multi part form request.

     The transmitted data currently includes:
     * **startLocLat:** The latitude of the first location
     * **startLocLon:** The longitude of the first location
     * **startLocTs:** The timestamp of the first location
     * **endLocLat:** The latitude of the last location
     * **endLocLon:** The longitude of the last location
     * **endLocTs:** The timestamp of the last location
     * **deviceId:** The world wide unqiue identifier of this device
     * **measurementId:** The device wide unique identifier of the transmitted measurement
     * **deviceType:** A string describing how this device identifies itself
     * **osVersion:** The version of the operating system installed on this device
     * **appVersion:** The version of the application running the Cyface SDK
     * **length:** The track length of the measurement that is going to be transmitted
     * **locationCount:** The number of locations in the track
     * **vehicle:** The vehicle used to capture the track

     - Parameters:
        - request: The request to add the meta data to
        - measurement: The measurement to take the meta data from
        - initialModality: The modality selected at the start of the measurement

     - Throws: `ServerConnectionError.dataError` if important data for the provided `measurement` is missing from the database.
     */
    func addMetaData(to request: MultipartFormData, for measurement: Measurement, withInitialModality initialModality: String) throws {
        guard let deviceIdData = installationIdentifier.data(using: String.Encoding.utf8) else {
            throw ServerConnectionError.dataError("Installation identifier was missing!")
        }
        guard let measurementIdData = String(measurement.identifier).data(using: String.Encoding.utf8) else {
            throw ServerConnectionError.dataError("Measurement identifier was missing!")
        }
        guard let deviceTypeData = modelIdentifier.data(using: String.Encoding.utf8) else {
            throw ServerConnectionError.dataError("Device model identifier was missing!")
        }

        let bundle = Bundle(for: type(of: self))
        guard let appVersion = (bundle.infoDictionary?["CFBundleShortVersionString"] as? String)?.data(using: String.Encoding.utf8) else {
            throw ServerConnectionError.dataError("Application version was missing!")
        }

        guard let vehicle = initialModality.data(using: String.Encoding.utf8) else {
            throw ServerConnectionError.dataError("No type of vehicle provided for measurement!")
        }

        let length = String(measurement.trackLength).data(using: String.Encoding.utf8)!

        let locationCount = measurement.tracks.map({ track in track.locations.count}).reduce(0, {result, value in result+value})
        let locationCountData = String(locationCount).data(using: String.Encoding.utf8)!
        let tracks = measurement.tracks.filter({ track in !track.locations.isEmpty})

        if !tracks.isEmpty {
            let startLocationRaw = tracks[0].locations.first
            let endLocationRaw = tracks.last?.locations.last

            if let startLocationRaw = startLocationRaw {
                let startLocationLat = "\(startLocationRaw.latitude)".data(using: String.Encoding.utf8)!
                let startLocationLon = "\(startLocationRaw.longitude)".data(using: String.Encoding.utf8)!
                let startLocationTs = "\(startLocationRaw.timestamp)".data(using: String.Encoding.utf8)!
                request.append(startLocationLat, withName: "startLocLat")
                request.append(startLocationLon, withName: "startLocLon")
                request.append(startLocationTs, withName: "startLocTs")
            }

            if let endLocationRaw = endLocationRaw {
                let endLocationLat = "\(endLocationRaw.latitude)".data(using: String.Encoding.utf8)!
                let endLocationLon = "\(endLocationRaw.longitude)".data(using: String.Encoding.utf8)!
                let endLocationTs = "\(endLocationRaw.timestamp)".data(using: String.Encoding.utf8)!
                request.append(endLocationLat, withName: "endLocLat")
                request.append(endLocationLon, withName: "endLocLon")
                request.append(endLocationTs, withName: "endLocTs")
            }
        }

        request.append(deviceIdData, withName: "deviceId")
        request.append(measurementIdData, withName: "measurementId")
        request.append(deviceTypeData, withName: "deviceType")
        request.append("iOS \(UIDevice.current.systemVersion)".data(using: String.Encoding.utf8)!, withName: "osVersion")
        request.append(appVersion, withName: "appVersion")
        request.append(length, withName: "length")
        request.append(locationCountData, withName: "locationCount")
        request.append(vehicle, withName: "vehicle")
    }

    /**
     Called by Alamofire when encoding the request by Alamofire was finished.
     Starts the actual data transmission if encoding was successful.

     - Parameters:
        - for: The measurement that was encoded into a transmission request
        - with: The encoded measurement.
        - onSuccess: Called if data transmission was successful. Gets the transmitted measurement as a parameter.
        - onFailure: Called if data transmission failed for some reason. Gets the transmitted measurement and information about the error.
     - Throws:
        - Some unspecified undocumented error if encoding has failed. But even if no error is thrown encoding might have failed. There is currently no way in Alamofire to know for sure.
     */
    func onEncodingComplete(for measurement: Int64, with result: SessionManager.MultipartFormDataEncodingResult, onSuccess success: @escaping ((Int64) -> Void), onFailure failure: @escaping ((Int64, Error) -> Void)) throws {
        os_log("encoding complete", log: ServerConnection.osLog, type: .default)
        switch result {
        case .success(let upload, _, _):
            // Two status codes are acceptable. A 201 is a successful upload, while a 409 is a conflict. In both cases the measurement should be marked as uploaded successfully.
            upload.validate(statusCode: [201, 409]).responseString { response in
                os_log("Validating Upload!", log: ServerConnection.osLog, type: .default)
                switch response.result {
                case .success:
                    success(measurement)
                case .failure(let error):
                    failure(measurement, error)
                }
            }
        case .failure(let error):
            throw error
        }
    }
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
    }
}

struct MetaData: Encodable {
    let locationCount: UInt64
    let formatVersion: Int
    let startLocLat: Double
    let startLocLon: Double
    let startLocTS: UInt64
    let endLocLat: Double
    let endLocLon: Double
    let endLocTS: UInt64
    let measurementId: UInt64
    let deviceId: String
    let deviceType: String
    let osVersion: String
    let applicationVersion: String
    let length: Double
    let modality: String
}
