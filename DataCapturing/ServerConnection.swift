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
    /// Session object to upload captured data to a Cyface server.
    private lazy var apiSession: URLSession = {
        return URLSession(configuration: .default)
    }()
    
    /// A `URL` used to upload data to. There should be a server complying to a Cyface REST interface available at that location.
    private let apiURL: URL
    
    /// Encoder used to format measurements into processable JSON for a Cyface server.
    private lazy var uploadMessagesEncoder = JSONEncoder()
    
    /// Authentication token provided by a JWT authentication request. This property is `nil` as long as àuthenticate was not called successfully yet. Otherwise it contains the JWT bearer required as content for the Authorization header.
    private var jwtBearer: String?
    
    /// Used to group measurements by app installation. This is necessary
    private lazy var installationIdentifier: String = {
        if let applicationIdentifier = UserDefaults.standard.string(forKey: "de.cyface.identifier") {
            return applicationIdentifier
        } else {
            let applicationIdentifier = UUID.init().uuidString
            UserDefaults.standard.set(applicationIdentifier, forKey: "de.cyface.identifier")
            return applicationIdentifier
        }
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
        guard let body = try? Data(self.uploadMessagesEncoder.encode(["login":"\(username)","password":"\(password)"])) else {
            fatalError("ServerConnection.authenticate(\(username), \(password)): Unable to encode username and password into a JSON request.")
        }
        request.httpBody = body
        
        
        if jwtBearer==nil {
            let authenticationTask = apiSession.dataTask(with: request) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        os_log("ServerConnection.authenticate(%@, %@): Unable to authenticate due to %@", username, password, error.localizedDescription)
                    }
                    if let handler = handler {
                        handler(error)
                    }
                    return
                }
                
                guard let unwrappedResponse = response as? HTTPURLResponse else {
                    DispatchQueue.main.async {
                        os_log("ServerConnection.authenticate(%@, %@): Unable to authenticate due to invalid response!", username, password)
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
                        os_log("ServerConnection.authenticate(%@, %@): Unable to authenticate due to missing Authorization header. Was your request targeted at a valid server?", username, password)
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
    
    public func sync(measurement: MeasurementMO) {
        guard isAuthenticated() else {
            fatalError("ServerConnection.sync(\(measurement.debugDescription)): Unable to sync with not authenticated client.")
        }
        
        var request = URLRequest(url: apiURL.appendingPathComponent("measurements"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(jwtBearer,forHTTPHeaderField: "Authorization")
        //request.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
        
        let chunks = self.makeUploadChunks(fromMeasurement: measurement)
        for chunk in chunks {
            guard let jsonChunk = try? JSONSerialization.data(withJSONObject: chunk, options: .sortedKeys) else {
            /*guard let jsonChunk = try? self.uploadMessagesEncoder.encode(chunk) else {*/
                fatalError("Invalid measurement format.")
            }
            
            let submissionTask = self.apiSession.uploadTask(with: request, from: jsonChunk) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        os_log("Server Error during upload of measurement %@! Encountered errror %@.", measurement, error.localizedDescription )
                    }
                    return
                }
                guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                    DispatchQueue.main.async {
                        os_log("Client Error during upload of measurement %@!",measurement)
                    }
                    return
                }
            }
            
            submissionTask.resume()
        }
    }
    
    public func isAuthenticated() -> Bool {
        return jwtBearer != nil || jwtBearer!.isEmpty
    }
    
    private func makeUploadChunks(fromMeasurement measurement: MeasurementMO) -> [[String:Any]] {
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
        
        return [["deviceId":String(installationIdentifier),"id":String(measurement.identifier),"vehicle":"BICYCLE","gpsPoints":geoLocations,"accelerationPoints":accelerationPoints]]
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
