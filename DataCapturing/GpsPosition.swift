//
//  GpsPosition.swift
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
 1.0.0
 
 - Since:
 1.0.0
 */
public struct GpsPosition {
    /**
     The captured latitude of this `GpsPosition` in decimal coordinates as a value between -90.0 (south pole) and 90.0 (north pole).
     */
    public let lat : Double
    /**
     The captured longitude of this `GpsPosition`in decimal coordinates as a value between -180.0 and 180.0.
     */
    public let lon : Double
    /**
     The current speed fo the measuring device according to its location sensor in meters per second.
     */
    public let speed : Double
    /**
     The current accuracy of the measuring device in meters.
     */
    public let accuracy : Float
    
    /**
     Creates a new completely initialized GpsPosition.
     
     - parameters:
        - lat: The captured latitude of this `GpsPosition` in decimal coordinates as a value between -90.0 (south pole) and 90.0 (north pole).
        - lon: The captured longitude of this `GpsPosition`in decimal coordinates as a value between -180.0 and 180.0.
        - speed: The current speed fo the measuring device according to its location sensor in meters per second.
        - accuracy: The current accuracy of the measuring device in meters.
 */
    public init(lat:Double,lon:Double,speed:Double,accuracy:Float) {
        guard lat >= -90.0 && lat <= 90.0 else {
             fatalError("Illegal value for latitude. Is required to be between -90.0 and 90.0 but was \(lat).")
        }
        
        guard lon >= -180.0 && lon <= 90.0 else {
            fatalError("Illegal value for longitude. Is required to be between -180.0 and 180.0 but was \(lon).")
        }
        
        guard speed >= 0.0 else {
            fatalError("Illegal value for speed. Is required to be positive but was \(speed).")
        }
        
        guard accuracy >= 0.0 else {
            fatalError("Illegal value for accuracy. Is required to be positive but was \(accuracy).")
        }
        
        self.lat = lat
        self.lon = lon
        self.speed = speed
        self.accuracy = accuracy
    }
}
