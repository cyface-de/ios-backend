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
import CoreData

/**
 Realizes a connection to a Cyface Collector server.

 An object of this class realizes a connection between an iOS app capturing some data and a Cyface Collector server receiving that data.
 The data is transmitted using HTTPS in chunks of one measurement.
 The transmission format is compressed Cyface binary format.
 The cyface binary format is created by a `CyfaceBinaryFormatSerializer`.

 This implementation follows code published here: https://gist.github.com/toddhopkinson/60cae9e48e845ce02bcf526f388cfa63

 - Author: Klemens Muthmann
 - Version: 7.0.1
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
    func onAuthenticated(token: String, measurement: Int64, onSuccess: @escaping (Int64) -> Void, onFailure: @escaping (Int64, Error) -> Void) {
        let url = apiURL.appendingPathComponent("measurements")
        let headers: HTTPHeaders = [
            "accept": "*/*",
            "Authorization": "Bearer \(token)",
            "Content-type": "multipart/form-data"
        ]

        let encode: ((MultipartFormData) -> Void) = {data in
            os_log("Encoding!", log: ServerConnection.osLog, type: OSLogType.default)
            do {
                try self.create(request: data, for: measurement)
            } catch let error {
                os_log("Encoding data failed! Error %{PUBLIC}@", log: ServerConnection.osLog, type: .error, error.localizedDescription)
            }
        }
        os_log("Transmitting measurement to URL %{PUBLIC}@!", log: ServerConnection.osLog, type: .debug, url.absoluteString)
        Networking.sharedInstance.sessionManager.upload(multipartFormData: encode, usingThreshold: SessionManager.multipartFormDataEncodingMemoryThreshold, to: url, method: .post, headers: headers, encodingCompletion: {encodingResult in
            do {
                try self.onEncodingComplete(for: measurement, with: encodingResult, onSuccess: onSuccess, onFailure: onFailure)
            } catch {
                onFailure(measurement, error)
            }
        })
    }

    /**
     Create a MultiPart/FormData request to transmit a measurement to a Cyface Collector server.

     - Parameters:
        - request: The request to fill with data
        - for: The measurement to transmit
     - Throws:
        - `ServerConnectionError.missingInstallationIdentifier` If there is no valid installation identifier to identify this SDK installation with a server
        - `ServerConnectionError.missingMeasurementIdentifier` If the current measurement has no valid device wide unique identifier
        - `ServerConnectionError.missingDeviceType` If the device type of this device could not be figured out
        - `PersistenceError.dataNotLoadable` If there is no such measurement
        - `PersistenceError.noContext` If there is no current context and no background context can be created. If this happens something is seriously wrong with CoreData
        - `PersistenceError.modelNotLoabable` If the model is not loadable
        - `PersistenceError.modelNotInitializable` If the model was loaded (so it is available) but can not be initialized
        - `SerializationError.missingData` If no track data was found
        - `SerializationError.invalidData` If the database provided inconsistent and wrongly typed data. Something is seriously wrong in these cases
        - `FileSupportError.notReadable` If the data file was not readable
        - Some unspecified errors from within CoreData
        - Some unspecified undocumented file system error if file was not accessible
     */
    func create(request: MultipartFormData, for measurement: Int64) throws {
        os_log("Creating request", log: ServerConnection.osLog, type: .default)
        // Load and serialize measurement synchronously.
        let persistenceLayer = PersistenceLayer(onManager: manager)
        persistenceLayer.context = persistenceLayer.makeContext()
        let measurement = try persistenceLayer.load(measurementIdentifiedBy: measurement)
        guard let modalityRawValue = try persistenceLayer.loadEvents(typed: .modalityTypeChange, forMeasurement: measurement)[0].value else {
            fatalError("Invalid modality change event with no value encountered!")
        }
        guard let initialModality = Modality(rawValue: modalityRawValue) else {
            fatalError("Unable to create modality from raw value \(modalityRawValue)!")
        }
        guard let events = measurement.events?.array as? [Event] else {
            fatalError("Unable to load events for measurement \(measurement.identifier)")
        }

        try addMetaData(to: request, for: measurement, withInitialModality: initialModality)

        let measurementFileWriter = MeasurementFile()
        let measurementFileURL = try measurementFileWriter.write(serializable: measurement, to: measurement.identifier)
        let measurementFileName = "\(self.installationIdentifier)_\(measurement.identifier).ccyf"
        request.append(measurementFileURL, withName: "fileToUpload", fileName: measurementFileName, mimeType: "application/octet-stream")

        let eventFileWriter = EventsFile()
        let eventFileURL = try eventFileWriter.write(serializable: events, to: measurement.identifier)
        let eventFileName = "\(self.installationIdentifier)_\(measurement.identifier)_.ccyfe"
        request.append(eventFileURL, withName: "eventsFile", fileName: eventFileName, mimeType: "application/octet-stream")
    }

    /**
     Adds the required meta data from a measurement to a multi part form request.

     The transmitted data currently includes:
     * startLocLat: The latitude of the first location
     * startLocLon: The longitude of the first location
     * startLocTs: The timestamp of the first location
     * endLocLat: The latitude of the last location
     * endLocLon: The longitude of the last location
     * endLocTs: The timestamp of the last location
     * deviceId: The world wide unqiue identifier of this device
     * measurementId: The device wide unique identifier of the transmitted measurement
     * deviceType: A string describing how this device identifies itself
     * osVersion: The version of the operating system installed on this device
     * appVersion: The version of the application running the Cyface SDK
     * length: The track length of the measurement that is going to be transmitted
     * locationCount: The number of locations in the track
     * vehicle: The vehicle used to capture the track

     - Parameters:
        - request: The request to add the meta data to
        - measurement: The measurement to take the meta data from
        - initialModality: The modality selected at the start of the measurement
     */
    func addMetaData(to request: MultipartFormData, for measurement: MeasurementMO, withInitialModality initialModality: Modality) throws {
        guard let deviceIdData = installationIdentifier.data(using: String.Encoding.utf8) else {
            fatalError("Installation identifier was missing!")
        }
        guard let measurementIdData = String(measurement.identifier).data(using: String.Encoding.utf8) else {
            fatalError("Measurement identifier was missing!")
        }
        guard let deviceTypeData = modelIdentifier.data(using: String.Encoding.utf8) else {
            fatalError("Device model identifier was missing!")
        }

        let bundle = Bundle(for: type(of: self))
        guard let appVersion = (bundle.infoDictionary?["CFBundleShortVersionString"] as? String)?.data(using: String.Encoding.utf8) else {
            fatalError("Application version was missing!")
        }

        guard let vehicle = initialModality.rawValue.data(using: String.Encoding.utf8) else {
            fatalError("No type of vehicle provided for measurement!")
        }

        let length = String(measurement.trackLength).data(using: String.Encoding.utf8)!

        let persistenceLayer = PersistenceLayer(onManager: manager)
        persistenceLayer.context = persistenceLayer.makeContext()
        let locationCount = try persistenceLayer.countGeoLocations(forMeasurement: measurement)
        let locationCountData = String(locationCount).data(using: String.Encoding.utf8)!

            if let startLocationRaw = (measurement.tracks?.firstObject as? Track)?.locations?.firstObject as? GeoLocationMO {
                let startLocationLat = "\(startLocationRaw.lat)".data(using: String.Encoding.utf8)!
                let startLocationLon = "\(startLocationRaw.lon)".data(using: String.Encoding.utf8)!
                let startLocationTs = "\(startLocationRaw.timestamp)".data(using: String.Encoding.utf8)!
                request.append(startLocationLat, withName: "startLocLat")
                request.append(startLocationLon, withName: "startLocLon")
                request.append(startLocationTs, withName: "startLocTs")
            }

            if let endLocationRaw = (measurement.tracks?.lastObject as? Track)?.locations?.lastObject as? GeoLocationMO {
                let endLocationLat = "\(endLocationRaw.lat)".data(using: String.Encoding.utf8)!
                let endLocationLon = "\(endLocationRaw.lon)".data(using: String.Encoding.utf8)!
                let endLocationTs = "\(endLocationRaw.timestamp)".data(using: String.Encoding.utf8)!
                request.append(endLocationLat, withName: "endLocLat")
                request.append(endLocationLon, withName: "endLocLon")
                request.append(endLocationTs, withName: "endLocTs")
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
     Write the provided `measurement` to a file for background synchronization

     - Parameter measurement: The measurement to serialize as a file.
     - Returns: The url of the file containing the measurement data.
     - Throws:
        - `SerializationError.missingData` If no track data was found.
        - `SerializationError.invalidData` If the database provided inconsistent and wrongly typed data. Something is seriously wrong in these cases.
        - `FileSupportError.notReadable` If the data file was not readable.
        - Some unspecified undocumented file system error if file was not accessible.
     */
    /*private func appendFile(for objectLoader: (() -> NSManagedObject)) throws -> URL {
        let payloadWriter = PayloadWriter()
        let object = objectLoader()
        return try payloadWriter.write(serializable: object, to: measurement.identifier)
    }*/
}

/**
 A structure encapsulating errors used by server connections.

 - Author: Klemens Muthmann
 - Version: 4.1.0
 - Since: 1.0.0
 */
public struct ServerConnectionError: Error {
    /**
     ```
     case authenticationNotSuccessful
     case notAuthenticated
     ```

     - Author: Klemens Muthmann
     - Version: 1.0.0
     - Since: 4.0.0
     */
    enum Category {
        /// If authentication was carried out but was not successful
        case authenticationNotSuccessful
        /// Error occuring if this client tried to communicate with the server without proper authentication.
        case notAuthenticated
    }
    /// The `Category` of this error.
    let type: Category
    /// A human readable explanation for the error.
    let verboseDescription: String
    /// The name of the method this error has occured within.
    let inMethodName: String
    /// The name of the file this error has occured within.
    let inFileName: String
    /// The number of the line of code this error has occured within.
    let atLineNumber: Int

    /**
     Handles a `ServerConnectionError` appropriately, by showing its details.

     - Parameter error: The error to handle.
     - Returns: The error description shown by this method call.
     */
    public static func handle(error: ServerConnectionError) -> String {
        let readableError = """
        \nERROR - operation: [\(error.type)];
        reason: [\(error.verboseDescription)];
        in method: [\(error.inMethodName)];
        in file: [\(error.inFileName)];
        at line: [\(error.atLineNumber)]\n
        """
        print(readableError)
        return readableError
    }
}
