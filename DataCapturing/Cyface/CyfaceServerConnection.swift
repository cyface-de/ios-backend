//
//  ServerConnection.swift
//  DataCapturing
//
//  Created by Team Cyface on 18.12.17.
//  Copyright © 2017 Cyface GmbH. All rights reserved.
//

import Foundation
import os.log

// TODO: The parameter for the finished handlers is called differently all the time
// TODO: Parameter order in the finished handler is not the same always (error is sometimes the first and sometimes the last parameter
// TODO: Maybe create an error handler to remove `nil` parameters
// TODO: Terminology: There is identifier, deviceIdentifier, appIdentifier and installationIdentifier which refers to the same thing always
/**
 Instances of this class represent connections to a Cyface server API. They upload data in the form of JSON chunks.
 
 - Author: Klemens Muthmann
 - Version: 2.0.0
 - Since: 1.0.0
 */
public class CyfaceServerConnection: ServerConnection {

    // MARK: - Properties
    /// The log system used to log messages to the terminal.
    private let LOG = OSLog(subsystem: "de.cyface", category: "ServerConnection")

    /// Session object to upload captured data to a Cyface server.
    private lazy var apiSession: URLSession = {
        return URLSession(configuration: .default)
    }()

    /// A `URL` used to upload data to. There should be a server complying to a Cyface REST interface available at that location.
    private let apiURL: URL

    /// Authentication token provided by a JWT authentication request. This property is `nil` as long as authenticate was not called successfully yet. Otherwise it contains the JWT bearer required as content for the Authorization header.
    private var jwtBearer: String?

    /**
     The handler to call after authentication has been finished. If an error occurs the error property of this handler contains further details. This property is `nil` after successful authentication.
    */
    private var onAuthenticationFinishedHandler: ((Error?) -> Void)?

    /**
     The world wide unique identifier of this app installation. The name is a bit misleading. It is used to identify multiple uploads from the same device, for example to create reusable machine learning models for one or only some devices. If the app is uninstalled and reinstalled, this identifier is reset to a new value. It is generated and registered with the server on the first upload.
    */
    private lazy var deviceModelIdentifier: String = {
        if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {return simulatorModelIdentifier}
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
    }()

    /// The `PersistenceLayer` used to load the data to upload from.
    private let persistenceLayer: PersistenceLayer

    // MARK: - Initializers
    /**
     Creates a new `ServerConnection` to the provided URL.

     - Parameters:
        - apiURL: A `URL` used to upload data to. There should be a server complying to a Cyface REST interface available at that location.
        - persistenceLayer: The `PersistenceLayer` used to load the data to upload from.
     */
    public required init(apiURL url: URL, persistenceLayer: PersistenceLayer) {
        self.apiURL=url
        self.persistenceLayer = persistenceLayer
    }

    // MARK: - Methods

    /**
     Authenticates this client against the API via `username` and `password` and calls the provided handler upon completion.

     - Parameters:
        - with: The name of the user to authenticate.
        - and: The password of the user to authenticate.
        - onFinish: A handler called after authentication has been finished. If an error occured, the provided parameter contains further details. If authentication was successful, that parameter is `nil`.
    */
    public func authenticate(with username: String, and password: String, onFinish handler: ((Error?) -> Void)?) {
        let loginURL = apiURL.appendingPathComponent("login")
        var request = URLRequest(url: loginURL)
        self.onAuthenticationFinishedHandler = handler
        request.httpMethod = "POST"
        request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        guard let body = try? JSONSerialization.data(withJSONObject: [
            "login": "\(username)",
            "password": "\(password)"]) else {
            fatalError("authenticate(username: \(username), password: \(password)): Unable to encode username and password into a JSON request.")
        }
        request.httpBody = body

        if jwtBearer==nil {
            let authenticationTask = apiSession.dataTask(with: request, completionHandler: onAuthenticationResponse)
            authenticationTask.resume()
        }
    }

    /**
     If this client is authenticated, this method uploads the provided measurement as JSON chunks to the endpoint used with this client.

     - SeeAlso: `ServerConnection.sync(measurement:onFinishedCall:)`
    */
    public func sync(measurement: MeasurementEntity, onFinishedCall handler: @escaping (MeasurementEntity, ServerConnectionError?) -> Void) {
        debugPrint("Trying to synchronize measurement \(measurement.identifier)")
        guard isAuthenticated() else {
            fatalError("CyfaceServerConnection.sync(measurementIdentifiedBy: \(measurement.identifier)): Unable to sync with not authenticated client.")
        }

        let measurementIdentifier = measurement.identifier
        installationIdentifier { error, deviceIdentifier in
            if let error = error {
                handler(measurement, error)
                return
            } else if let identifier = deviceIdentifier {
                self.transmit(measurement: measurement, forDevice: identifier, onFinish: handler)
            } else {
                fatalError("CyfaceServerConnection.sync(measurement: \(measurementIdentifier)): Neither identifier nor error information available.")
            }
        }
    }

    /// - SeeAlso: `ServerConnection.isAuthenticated()
    public func isAuthenticated() -> Bool {
        return jwtBearer != nil && !jwtBearer!.isEmpty
    }

    /// - SeeAlso: `ServerConnection.getURL()`
    public func getURL() -> URL {
        return apiURL
    }

    /**
     Transmits the provided `measurement` from the device identified by `forDevice` to the API endpoint URL used by this client and calls `onFinish` when done.

     - Parameters:
        - measurement: The `measurement` to transmit.
        - forDevice: The identifier of this device used to identify the data on the server side.
        - onFinish: Called upon upload completion. This handler is provided with the uploaded `MeasurementEntity` and either some error information if there was an error, or `nil` if upload has been successful.
    */
    private func transmit(measurement: MeasurementEntity, forDevice deviceIdentifier: String, onFinish handler: @escaping (MeasurementEntity, ServerConnectionError?) -> Void) {

        var request = URLRequest(url: apiURL.appendingPathComponent("measurements"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(jwtBearer, forHTTPHeaderField: "Authorization")

        makeUploadChunks(fromMeasurement: measurement, forInstallation: deviceIdentifier) { chunk in
            guard let jsonChunk = try? JSONSerialization.data(withJSONObject: chunk, options: .sortedKeys) else {
                fatalError("ServerConnection.transmit(measurement: \(measurement.identifier), forDevice: \(deviceIdentifier)): Invalid measurement format.")
            }

            let submissionTask = self.apiSession.uploadTask(with: request, from: jsonChunk) { _, response, error in
                if let error = error {
                    handler(measurement, ServerConnectionError(
                        title: "Data Transmission Error",
                        description: "Error while transmitting data to the server at \(self.apiURL)! Error was: \(error)"))
                    return
                }
                guard let response = response as? HTTPURLResponse else {
                    handler(measurement, ServerConnectionError(
                        title: "Data Transmission Error",
                        description: "Received erroneous response from \(String(describing: request.url))!"))
                    return
                }

                let statusCode = response.statusCode
                guard statusCode == 201 else {
                    handler(measurement, ServerConnectionError(
                        title: "Invalid Status Code Error",
                        description: "Invalid status code \(statusCode) received from server at \(String(describing: request.url))!"))
                    return
                }

                handler(measurement, nil)
            }
            submissionTask.resume()
        }
    }

    /**
     This function chunks the data into smaller packets of JSON data to upload.

     - Todo: Currently this method produces only one large chunk. A future implementation should implement the actual chunking as it is on Android

     - Parameters:
        - measurement: The measurement to create chunks from
        - installationIdentifier: The world wide unique device identifier identifying this app installation.
        - onChunkFinishedCall: A handler to call when a chunk is finished. This handler is provided with the finished chunk as a parameter.
    */
    private func makeUploadChunks(
        fromMeasurement measurement: MeasurementEntity,
        forInstallation installationIdentifier: String, onChunkFinishedCall handler: @escaping ([String: Any]) -> Void) {

        persistenceLayer.load(measurementIdentifiedBy: measurement.identifier) { measurement in

            var geoLocations = [[String: String]]()
            if let measurementLocations = measurement.geoLocations {
                for location in measurementLocations {
                    geoLocations.append([
                        "lat": String(location.lat),
                        "lon": String(location.lon),
                        "speed": String(location.speed),
                        "timestamp": String(location.timestamp),
                        "accuracy": String(Int(location.accuracy))])
                }
            }

            var accelerationPoints = [[String: String]]()
            if let accelerations = measurement.accelerations {
                for acceleration in accelerations {
                    accelerationPoints.append([
                        "ax": String(acceleration.ax),
                        "ay": String(acceleration.ay),
                        "az": String(acceleration.az),
                        "timestamp": String(acceleration.timestamp)])
                }
            }

            handler([
                "deviceId": installationIdentifier,
                "id": String(measurement.identifier),
                "vehicle": "BICYCLE",
                "gpsPoints": geoLocations,
                "accelerationPoints": accelerationPoints])
        }
    }

    /**
     Used to register this application with the server.
     The method checks whether an application identifier has been generated.
     If not it generates one and registers it with the server.
     If there already is an existing application identifier registered it looks whether the server
     knows about that identifier and if not registers it.
     
     - Parameter handler: Handler called when registration with the server has been completed. This handler is provided with the identifier and some error information if an error occured. If retrieving or generating the identifier was successful the error information is `nil`.
     */
    private func installationIdentifier(
        withCompletionHandler handler: @escaping (ServerConnectionError?, String?) -> Void) {

        let completionHandler: (ServerConnectionError?, String?) -> Void = { error, appIdentifier in
            if let error = error {
                handler(error, nil)
                return
            }
            guard let appIdentifier = appIdentifier else {
                handler(ServerConnectionError(
                    title: "Device Registration Error",
                    description: "Unable to get application identifier"), nil)
                return
            }

            UserDefaults.standard.set(appIdentifier, forKey: "de.cyface.identifier")
            handler(nil, appIdentifier)
        }

        if let applicationIdentifier = UserDefaults.standard.string(forKey: "de.cyface.identifier") {
            // Check if identifier is registered at server.
            checkDevice(withIdentifier: applicationIdentifier) { error, identifierFound in
                if let error = error {
                    handler(error, nil)
                    return
                }
                if identifierFound {
                    // Identifier was registered
                    handler(nil, applicationIdentifier)
                } else {
                    // Identifier was not registered. Register again.
                    self.registerDevice(withIdentifier: applicationIdentifier, completionHandler: completionHandler)
                }
            }

        } else {
            // otherwise generate new application identifier
            let applicationIdentifier = UUID.init().uuidString
            registerDevice(withIdentifier: applicationIdentifier, completionHandler: completionHandler)
        }
    }

    // TODO: From the name of the function it is not clear, what the boolean value means.
    /**
     Checks whether a given device exists on the server or not. If this is a new device it should not exist and need to be registered. If the device exists it should not be registered again.

     - Parameters:
        - withIdentifier: The device identifier to check.
        - completionHandler: The handler to call when the check has finished. This is provided with some error information, which is `nil` if checking was successful. The result of the check is provided as a `Bool` value that is `true` if the device exists and `false` otherwise.
    */
    private func checkDevice(
        withIdentifier identifier: String,
        completionHandler handler: @escaping (ServerConnectionError?, Bool) -> Void) {

        guard isAuthenticated() else {
            fatalError("""
                ServerConnection.checkDevice(\(identifier)): Unable to check for registered device
                for non-authenticated client.
                """)
        }

        var request = URLRequest(url: self.apiURL.appendingPathComponent("devices"))
        request.httpMethod = "GET"
        request.setValue(jwtBearer, forHTTPHeaderField: "Authorization")

        let deviceRetrievalTask = self.apiSession.dataTask(with: request) { data, response, error in
            if let error = error {
                handler(ServerConnectionError(
                    title: "Device Registration Error",
                    description: "Server error while checking if server knows me!, Error \(error)"), false)
                return
            }

            guard let response = response as? HTTPURLResponse else {
                handler(ServerConnectionError(
                    title: "Device Registration Error",
                    description: "Invalid reponse received while checking for registered device"), false)
                return
            }

            guard response.statusCode == 200 else {
                handler(ServerConnectionError(
                    title: "Device Registration Error",
                    description: """
                    Invalid status code while checking if device exists. Status Code: \(response.statusCode)
                    """), false)
                return
            }

            guard let data = data else {
                handler(ServerConnectionError(
                    title: "Device Registration Error",
                    description: "Unable to unwrap server response from checking for existing device."), false)
                return
            }

            var foundDevice = false
            if let devices = try? JSONDecoder().decode([Device].self, from: data) {
                for device in devices {
                    foundDevice = (device.identifier==identifier) || foundDevice
                }
            }

            handler(nil, foundDevice)

        }

        deviceRetrievalTask.resume()
    }

    /**
     Registers a device with the provided identifier on the server.

     - Parameters:
        - withIdentifier: The world wide unique identifier of the device to register.
        - completionHandler: A handler called after device registration has completed. This is provided with some error information, which is `nil` if registration was successful. The registered device identifier is always provided as a parameter. This should be the same as the one provided to this method call.

     - SeeAlso: Property `installationIdentifier`
     */
    private func registerDevice(
        withIdentifier identifier: String,
        completionHandler handler: @escaping (ServerConnectionError?, String?) -> Void) {

        guard isAuthenticated() else {
            fatalError("""
                ServerConnection.registerDevice(\(identifier)): Unable to register device for non-authenticated client.
                """)
        }

        var request = URLRequest(url: self.apiURL.appendingPathComponent("devices"))
        request.httpMethod = "POST"
        request.setValue(jwtBearer, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let deviceCreationBody = ["id": identifier, "name": deviceModelIdentifier]
        request.httpBody = try? JSONSerialization.data(withJSONObject: deviceCreationBody, options: .sortedKeys)

        let deviceCreationTask = self.apiSession.dataTask(with: request) { _, response, error in
            if let error = error {
                handler(ServerConnectionError(
                    title: "Device Registration Error",
                    description: "Server error during device registration!, Error \(error)"), identifier)
                return
            }

            guard let response = response as? HTTPURLResponse else {
                handler(ServerConnectionError(
                    title: "Device Registration Error",
                    description: """
                    Unable to unwrap response received after trying to register device with \(self.apiURL)).
                    """), identifier)
                return
            }

            guard response.statusCode == 201 else {
                handler(ServerConnectionError(
                    title: "Device Registration Error",
                    description: """
                    Invalid response status code \(response.statusCode) from server \(String(describing: request.url))!
                    """), identifier)
                return
            }

            handler(nil, identifier)
        }

        deviceCreationTask.resume()
    }

    /**
     A Handler called when a request for authentication returns.

     - Parameters:
        - response: The response received as reaction to the request.
        - error: An optional error parameter that is `nil` if the response was successful.

     - SeeAlso `authenticate(with:and:onFinish)`
    */
    private func onAuthenticationResponse(_: Data?, response: URLResponse?, error: Error?) {
        guard let handler = onAuthenticationFinishedHandler else {
            fatalError("No handler for authentication finished event available!")
        }

        if let error = error {
            handler(error)
            return
        }

        guard let unwrappedResponse = response as? HTTPURLResponse else {
            handler(ServerConnectionError(
                title: "Authentication Error",
                description: """
                There has been a client side error while authenticating with the Cyface API available at \(self.apiURL).
                """))
            return
        }

        let statusCode = unwrappedResponse.statusCode
        let authenticationToken = unwrappedResponse.allHeaderFields["Authorization"] as? String

        guard let unwrappedAuthenticationToken = authenticationToken else {
            handler(ServerConnectionError(
                title: "Authentication Error",
                description: "No Authorization token received from Cyface API available at \(self.apiURL)."))
            return
        }

        if statusCode == 200 {
            self.jwtBearer = unwrappedAuthenticationToken
            handler(nil)
        } else {
            handler(ServerConnectionError(
                title: "Authentication Error",
                description: """
                There has been a client side error while authenticating with the Cyface API
                available at \(self.apiURL).
                The call provided the following status code \(statusCode).
                """))
        }
    }
}

// MARK: - Support Classes

/**
 Struct representing a JSON answer to a GET request for devices.

 - SeeAlso: CyfaceServerConnection.checkDevice(withIdentifier:completionHandler:)

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 2.0.0
 */
struct Device: Codable {
    /// The world wide unique identifier of the device.
    var identifier: String
}
