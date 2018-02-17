//
//  ServerConnection.swift
//  DataCapturing
//
//  Created by Team Cyface on 18.12.17.
//  Copyright © 2017 Cyface GmbH. All rights reserved.
//

import Foundation
import os.log

/**
 Instances of this class represent connections to a Cyface server API.
 
 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 1.0.0
 */
public class ServerConnection {
    
    // MARK: Properties
    private let LOG = OSLog(subsystem: "de.cyface",category: "ServerConnection")
    
    /// Session object to upload captured data to a Cyface server.
    private lazy var apiSession: URLSession = {
        return URLSession(configuration: .default)
    }()
    
    /// A `URL` used to upload data to. There should be a server complying to a Cyface REST interface available at that location.
    private let apiURL: URL
    
    /// Authentication token provided by a JWT authentication request. This property is `nil` as long as àuthenticate was not called successfully yet. Otherwise it contains the JWT bearer required as content for the Authorization header.
    private var jwtBearer: String?
    
    private lazy var deviceModelIdentifier: String = {
        if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {return simulatorModelIdentifier}
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
    }()
    
    // MARK: Initializers
    /**
     Creates a new `ServerConnection` to the provided URL.
     - Parameters:
     -  url: A `URL` used to upload data to. There should be a server complying to a Cyface REST interface available at that location.
     */
    public init(apiURL url: URL) {
        self.apiURL=url
    }
    
    // MARK: Methods
    public func authenticate(with username: String, and password: String, onFinish handler: ((Error?) -> Void)?) {
        let loginURL = apiURL.appendingPathComponent("login")
        var request = URLRequest(url: loginURL)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        guard let body = try? JSONSerialization.data(withJSONObject: ["login":"\(username)","password":"\(password)"]) else {
            fatalError("authenticate(username: \(username), password: \(password)): Unable to encode username and password into a JSON request.")
        }
        request.httpBody = body
        
        
        if jwtBearer==nil {
            let authenticationTask = apiSession.dataTask(with: request) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        os_log("authenticate(username: %@, password: %@): Encountered error: %@", log: self.LOG, type: .error, username, password, error as CVarArg)
                    }
                    if let handler = handler {
                        handler(error)
                    }
                    return
                }
                
                guard let unwrappedResponse = response as? HTTPURLResponse else {
                    DispatchQueue.main.async {
                        os_log("authenticate(username: %@, password: %@): Unable to authenticate due to invalid response!", log: self.LOG, type: .error, username, password)
                    }
                    if let handler = handler {
                        handler(ServerConnectionError(title: "Authentication Error", description: "There has been a client side error while authenticating with the Cyface API available at \(self.apiURL).", code: 1))
                    }
                    return
                }
                
                let statusCode = unwrappedResponse.statusCode
                let authenticationToken = unwrappedResponse.allHeaderFields["Authorization"] as? String
                
                guard let unwrappedAuthenticationToken = authenticationToken else {
                    DispatchQueue.main.async {
                        os_log("authenticate(username: %@, password: %@): Unable to authenticate due to missing Authorization header. Was your request targeted at a valid server?", log: self.LOG, type: .error, username, password)
                    }
                    if let handler = handler {
                        handler(ServerConnectionError(title: "Authentication Error", description: "No Authorization token received from Cyface API available at \(self.apiURL).", code: 1))
                    }
                    return
                }
                
                if statusCode == 200 {
                    self.jwtBearer = unwrappedAuthenticationToken
                    if let handler = handler {
                        handler(nil)
                    }
                } else  {
                    DispatchQueue.main.async {
                        os_log("ServerConnection.authenticate(%@, %@): Unexpected response status during authentication!",username, password)
                    }
                    if let handler = handler {
                        handler(ServerConnectionError(title: "Authentication Error", description: "There has been a client side error while authenticating with the Cyface API available at \(self.apiURL). The call to \(loginURL) provided the following status code \(statusCode).", code: 1))
                    }
                }
            }
            authenticationTask.resume()
        }
    }
    
    public func sync(measurement: MeasurementMO, onFinish handler: @escaping (ServerConnectionError?) -> ()) {
        guard isAuthenticated() else {
            fatalError("sync(measurement: \(measurement)): Unable to sync with not authenticated client.")
        }
        
        installationIdentifier { error, identifier in
            if let error = error {
                DispatchQueue.main.async {
                    os_log("sync(measurement: %@): Encountered error while fetching installation identifier: %@!",log: self.LOG, type: .error, measurement, error.localizedDescription)
                }
                handler(error)
                return
            } else if let identifier = identifier {
                self.transmit(measurement: measurement, forDevice: identifier, onFinish: handler)
            } else {
                fatalError("ServerConnection.sync(measurement: \(measurement)): Neither identifier nor error information available.")
            }
        }
    }
    
    public func isAuthenticated() -> Bool {
        return jwtBearer != nil || jwtBearer!.isEmpty
    }
    
    private func transmit(measurement: MeasurementMO, forDevice deviceIdentifier: String, onFinish handler: @escaping (ServerConnectionError?) -> ()) {
        var request = URLRequest(url: apiURL.appendingPathComponent("measurements"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(jwtBearer, forHTTPHeaderField: "Authorization")
        //request.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
        
        
        let chunks = self.makeUploadChunks(fromMeasurement: measurement, forInstallation: deviceIdentifier)
        for chunk in chunks {
            guard let jsonChunk = try? JSONSerialization.data(withJSONObject: chunk, options: .sortedKeys) else {
                /*guard let jsonChunk = try? self.uploadMessagesEncoder.encode(chunk) else {*/
                fatalError("ServerConnection.transmit(measurement: \(measurement.debugDescription), forDevice: \(deviceIdentifier)): Invalid measurement format.")
            }
            
            let submissionTask = self.apiSession.uploadTask(with: request, from: jsonChunk) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        os_log("transmit(measurement: %@, forDevice: %@): Server Error during upload! Encountered error %@.", log: self.LOG, type: .error, measurement, deviceIdentifier, error.localizedDescription)
                    }
                    handler(ServerConnectionError(title: "Data Transmission Error", description: "Error while transmitting data to the server at \(String(describing: request.url))!", code: 3))
                    return
                }
                guard let response = response as? HTTPURLResponse else {
                    DispatchQueue.main.async {
                        os_log("transmit(measurement: %@, forDevice: %@): Client Error during upload!",log: self.LOG, type: .error, measurement, deviceIdentifier)
                    }
                    handler(ServerConnectionError(title: "Data Transmission Error", description: "Received erroneous response from \(String(describing: request.url))!", code: 3))
                    return
                }
                
                let statusCode = response.statusCode
                guard statusCode == 201 else {
                    /*DispatchQueue.main.async {
                     os_log("transmit(measurement: %@, forDevice: %@): Received wrong status code from server. Expected 201 but was %@", log: self.LOG, type: .error, measurement, deviceIdentifier, statusCode)
                     }*/
                    handler(ServerConnectionError(title: "Invalid Status Code Error", description: "Invalid status code \(statusCode) received from server at \(String(describing: request.url))!", code: 3))
                    return
                }
                
                handler(nil)
            }
            
            submissionTask.resume()
        }
    }
    
    private func makeUploadChunks(fromMeasurement measurement: MeasurementMO, forInstallation identifier: String) -> [[String:Any]] {
        // TODO: Not really chunked yet. Still loads everything into main memory.
        var geoLocations = [[String:String]]()
        if let measurementLocations = measurement.geoLocations {
            for location in measurementLocations {
                let location = location as! GeoLocationMO
                geoLocations.append(["lat":String(location.lat),"lon":String(location.lon),"speed":String(location.speed),"timestamp":String(location.timestamp),"accuracy":String(Int(location.accuracy))])
            }
        }
        
        var accelerationPoints = [[String:String]]()
        if let accelerations = measurement.accelerations {
            for acceleration in accelerations {
                let acceleration = acceleration as! AccelerationPointMO
                accelerationPoints.append(["ax": String(acceleration.ax),"ay": String(acceleration.ay),"az": String(acceleration.az),"timestamp": String(acceleration.timestamp)])
            }
        }
        
        return [["deviceId":identifier,"id":String(measurement.identifier),"vehicle":"BICYCLE","gpsPoints":geoLocations,"accelerationPoints":accelerationPoints]]
    }
    
    /**
     Used to register this application with the server. The method checks whether an application identifier has been generated. If not it generates one and registers it with the server. If there already is an existing application identifier registered it looks whether the server knows about that identifier and if not registers it.
     
     - Parameter handler: Handler called when registration with the server has been completed.
     */
    private func installationIdentifier(withCompletionHandler handler: @escaping (ServerConnectionError?, String?) -> ()) {
        let completionHandler : (ServerConnectionError?,String?) -> () = { error, appIdentifier in
            if let error = error {
                handler(error,nil)
                return
            }
            guard let appIdentifier = appIdentifier else {
                handler(ServerConnectionError(title:"Device Registration Error",description:"Unable to get application identifier",code:1),nil)
                return
            }
            
            UserDefaults.standard.set(appIdentifier, forKey: "de.cyface.identifier")
            handler(nil,appIdentifier)
        }
        
        if let applicationIdentifier = UserDefaults.standard.string(forKey: "de.cyface.identifier") {
            // Check if identifier is registered at server.
            checkDevice(withIdentifier:applicationIdentifier) { error, identifierFound in
                if let error = error {
                    handler(error,nil)
                    return
                }
                if identifierFound {
                    // Identifier was registered
                    handler(nil,applicationIdentifier)
                } else {
                    // Identifier was not registered. Register again.
                    self.registerDevice(withIdentifier: applicationIdentifier, completionHandler: completionHandler)
                }
            }
            
        } else {
            // Generate new application identifier
            let applicationIdentifier = UUID.init().uuidString
            
            registerDevice(withIdentifier:applicationIdentifier,completionHandler: completionHandler)
        }
    }
    
    private func checkDevice(withIdentifier identifier: String, completionHandler handler: @escaping (ServerConnectionError?,Bool) -> ()) {
        guard isAuthenticated() else {
            fatalError("ServerConnection.checkDevice(\(identifier)): Unable to check for registered device for non-authenticated client.")
        }
        
        var request = URLRequest(url:self.apiURL.appendingPathComponent("devices"))
        request.httpMethod = "GET"
        request.setValue(jwtBearer, forHTTPHeaderField: "Authorization")
        
        let deviceRetrievalTask = self.apiSession.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    os_log("checkDevice(%@): Server error while checking if server knows me! Error %@",log: self.LOG, type: .error, identifier, error.localizedDescription)
                }
                handler(ServerConnectionError(title: "Device Registration Error", description: "Server error while checking if server knows me!, Error \(error)",code: 3),false)
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                handler(ServerConnectionError(title: "Device Registration Error", description: "Invalid reponse received while checking for registered device", code: 4),false)
                return
            }
            
            guard response.statusCode == 200 else {
                handler(ServerConnectionError(title: "Device Registration Error", description: "Invalid status code while checking if device exists. Status Code: \(response.statusCode)", code: 5), false)
                return
            }
            
            guard let data = data else {
                handler(ServerConnectionError(title: "Device Registration Error", description: "Unable to unwrap server response from checking for existing device.", code: 6), false)
                return
            }
            
            var foundDevice = false
            if let devices = try? JSONDecoder().decode([Device].self, from: data) {
                for device in devices {
                    foundDevice = (device.id==identifier) || foundDevice
                }
            }
            
            handler(nil,foundDevice)
            
        }
        
        deviceRetrievalTask.resume()
    }
    
    private func registerDevice(withIdentifier identifier: String, completionHandler handler: @escaping (ServerConnectionError?,String?) -> ()) {
        guard isAuthenticated() else {
            fatalError("ServerConnection.registerDevice(\(identifier)): Unable to register device for non-authenticated client.")
        }
        
        var request = URLRequest(url: self.apiURL.appendingPathComponent("devices"))
        request.httpMethod = "POST"
        request.setValue(jwtBearer, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let deviceCreationBody = ["id":identifier,"name":deviceModelIdentifier]
        request.httpBody = try? JSONSerialization.data(withJSONObject: deviceCreationBody, options: .sortedKeys)
        
        let deviceCreationTask = self.apiSession.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    os_log("registerDevice(withIdentifier: %@): Server error during device registration! Error %@", log: self.LOG, type: .error, identifier, error.localizedDescription)
                }
                handler(ServerConnectionError(title: "Device Registration Error", description: "Server error during device registration!, Error \(error)", code: 2),identifier)
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    os_log("registerDevice(withIdentifier: %@): Client side error!", log: self.LOG, type: .error, identifier)
                }
                handler(ServerConnectionError(title: "Device Registration Error", description: "Unable to unwrap response received after trying to register device with \(String(describing: request.url)).", code: 2),identifier)
                return
            }
            
            guard response.statusCode == 201 else {
                DispatchQueue.main.async {
                    os_log("registerDevice(withIdentifier: %@): Invalid response status %@!", log: self.LOG, type: .error, identifier, response.statusCode)
                }
                handler(ServerConnectionError(title: "Device Registration Error", description: "Invalid response status code \(response.statusCode) from server \(String(describing: request.url))!", code: 2),identifier)
                return
            }
            
            handler(nil,identifier)
        }
        
        deviceCreationTask.resume()
    }
}

public struct ServerConnectionError: LocalizedError {
    
    var title: String?
    var code: Int
    public var errorDescription: String? { return _description }
    public var failureReason: String? { return _description }
    
    private var _description: String
    
    init(title: String?, description: String, code: Int) {
        self.title = title ?? "Error"
        self._description = description
        self.code = code
    }
}

struct Device: Codable {
    var id: String
}
