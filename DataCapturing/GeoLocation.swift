//
//  GeoLocation.swift
//  DataCapturingServices
//
//  Created by Team Cyface on 03.11.17.
//  Copyright © 2017 Cyface GmbH. All rights reserved.
//

import Foundation

/**
 A position captured by the `DataCapturingService`.
 
 - Author:
 Klemens Muthmann
 
 - Version:
 1.1.0
 
 - Since:
 1.0.0
 */
public struct GeoLocation {
    // MARK: Properties
    /**
     The captured latitude of this `GeoLocation` in decimal coordinates as a value between -90.0 (south pole) and 90.0 (north pole).
     */
    public let lat : Double
    /**
     The captured longitude of this `GeoLocation` in decimal coordinates as a value between -180.0 and 180.0.
     */
    public let lon : Double
    /**
     The current speed fo the measuring device according to its location sensor in meters per second.  iOS sets this to a negative value if speed is very low or invalid.
     */
    public let speed : Double
    /**
     The current accuracy of the measuring device in meters.
     */
    public let accuracy : Double
    /**
     The time this location was captured as UTC timestamp (milliseconds since january 1st 1970 00:00:00).
    */
    public let timestamp : Int64
    
    // MARK: Initializers
    /**
     Creates a new completely initialized GeoLocation.
     
     - parameters:
        - lat: The captured latitude of this `GeoLocation` in decimal coordinates as a value between -90.0 (south pole) and 90.0 (north pole).
        - lon: The captured longitude of this `GeoLocation` in decimal coordinates as a value between -180.0 and 180.0.
        - speed: The current speed fo the measuring device according to its location sensor in meters per second. iOS sets this to a negative value if speed is very low or invalid.
        - accuracy: The current accuracy of the measuring device in meters.
        - timestamp: The time this location was captured as UTC timestamp (milliseconds since january 1st 1970 00:00:00).
    */
    public init(lat:Double,lon:Double,speed:Double,accuracy:Double,timestamp:Int64) {
        guard lat >= -90.0 && lat <= 90.0 else {
             fatalError("Illegal value for latitude. Is required to be between -90.0 and 90.0 but was \(lat).")
        }
        
        guard lon >= -180.0 && lon <= 180.0 else {
            fatalError("Illegal value for longitude. Is required to be between -180.0 and 180.0 but was \(lon).")
        }
        
        guard accuracy >= 0.0 else {
            fatalError("Illegal value for accuracy. Is required to be positive floating point value but was \(accuracy).")
        }
        guard timestamp>=0 else {
            fatalError("Illegal value for timestamp. Is required to be positive 64-bit integer but was \(timestamp)")
        }
        
        self.lat = lat
        self.lon = lon
        self.speed = speed
        self.accuracy = accuracy
        self.timestamp = timestamp
    }
}
