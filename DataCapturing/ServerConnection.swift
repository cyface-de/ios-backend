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
    public func authenticate(with username: String, and password: String) -> Bool {
        var request = URLRequest(url: apiURL.appendingPathComponent("login"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        guard let body = try? Data(self.uploadMessagesEncoder.encode(["login":username,"password":password])) else {
            fatalError("ServerConnection.authenticate(\(username),\(password)): Unable to encode username and password into a JSON request.")
        }
        request.httpBody = body
        
        if jwtBearer==nil {
            let authenticationTask = apiSession.dataTask(with: apiURL.appendingPathComponent("login")) { data, response, error in
                if let error = error {
                    os_log("Unable to authenticate due to %@", error.localizedDescription)
                    return
                }
                let data = data!
                
                guard let unwrappedResponse = response as? HTTPURLResponse, unwrappedResponse.statusCode == 200 else {
                    os_log("Unable to authenticate.")
                    return
                }
                
                if unwrappedResponse.mimeType=="application/json" {
                    self.jwtBearer = String (data: data, encoding: .utf8)
                }
            }
            authenticationTask.resume()
        }
        return isAuthenticated()
    }
    
    public func sync(measurement: MeasurementMO) {
        guard isAuthenticated() else {
            fatalError("ServerConnection.sync(\(measurement.debugDescription)): Unable to sync with not authenticated client.")
        }
        
        var request = URLRequest(url: apiURL.appendingPathComponent("measurements"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(jwtBearer,forHTTPHeaderField: "Authorization")
        
        let chunks = self.makeUploadChunks(fromMeasurement: measurement)
        for chunk in chunks {
            guard let jsonChunk = try? self.uploadMessagesEncoder.encode(chunk) else {
                fatalError("Invalid measurement format.")
            }
            
            let submissionTask = self.apiSession.uploadTask(with: request, from: jsonChunk) { data, response, error in
                if let error = error {
                    os_log("Server Error during upload of measurement %@! Encountered errror %@.", measurement, error.localizedDescription )
                    return
                }
                guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                    os_log("Client Error during upload of measurement %@!",measurement)
                    return
                }
            }
            
            submissionTask.resume()
        }
    }
    
    public func isAuthenticated() -> Bool {
        return jwtBearer != nil
    }
    
    private func makeUploadChunks(fromMeasurement measurement: MeasurementMO) -> [[String:Encodable]] {
        // TODO: Not really chunked yet. Still loads everything into main memory.
        var geoLocations = [[String:Any]]()
        if let measurementLocations = measurement.geoLocations {
            for location in measurementLocations {
                let location = location as! GeoLocationMO
                geoLocations.append(["\"lat\"":location.lat,"\"lon\"":location.lon,"\"speed\"":location.speed,"\"timestamp\"":location.timestamp,"\"accuracy\"":location.accuracy])
            }
        }
        
        var accelerationPoints = [[String:Encodable]]()
        if let accelerations = measurement.accelerations {
            for acceleration in accelerations {
                let acceleration = acceleration as! AccelerationPointMO
                accelerationPoints.append(["\"ax\"": acceleration.ax,"\"ay\"": acceleration.ay,"\"az\"": acceleration.az,"\"timestamp\"": acceleration.timestamp])
            }
        }
        
        return [["\"deviceId\"":"\"\(installationIdentifier)\"","\"id\"":measurement.identifier,"\"vehicle\"":"\"BICYCLE\"","\"gpsPoints\"":geoLocations,"\"accelerationPoints\"":accelerationPoints]]
    }
}
