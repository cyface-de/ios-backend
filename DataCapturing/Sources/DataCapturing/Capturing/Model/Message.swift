//
//  File.swift
//  
//
//  Created by Klemens Muthmann on 13.05.23.
//

import Foundation

public enum Message {
    case capturedLocation(GeoLocation)
    case capturedAltitude(Altitude)
    case capturedAcceleration(SensorValue)
    case capturedRotation(SensorValue)
    case capturedDirection(SensorValue)
    case started(timestamp: Date)
    case stopped(timestamp: Date)
    case paused(timestamp: Date)
    case resumed(timestamp: Date)
    case hasFix
    case fixLost
    case modalityChanged(to: String)
}
