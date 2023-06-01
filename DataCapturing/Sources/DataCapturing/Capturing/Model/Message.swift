//
//  File.swift
//  
//
//  Created by Klemens Muthmann on 13.05.23.
//

import Foundation

public enum Message: CustomStringConvertible {
    public var description: String {
        switch self {
        case .capturedLocation(let location):
            return "Captured location \(location)"
        case .capturedAltitude(let altitude):
            return "Captured altitude \(altitude)"
        case .capturedAcceleration(let value):
            return "Captured acceleration \(value)"
        case .capturedRotation(let value):
            return "Captured roration \(value)"
        case .capturedDirection(let value):
            return "Captured direction \(value)"
        case .started(let time):
            return "Started measurement at \(time)"
        case .stopped(let time):
            return "Stopped measurement at \(time)"
        case .paused(let time):
            return "Paused measurement at \(time)"
        case .resumed(let time):
            return "Resumed measurement at \(time)"
        case .hasFix:
            return "Has Fix"
        case .fixLost:
            return "Fix lost"
        case .modalityChanged(let modality):
            return "Modality changed to \(modality)"
        }
    }

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
