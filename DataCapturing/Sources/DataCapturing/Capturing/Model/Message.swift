//
//  File.swift
//  
//
//  Created by Klemens Muthmann on 13.05.23.
//

import Foundation

/**
 An enumeration of all the messages required during a measurement.

 - Author: Klemens Muthmann
 - Version 1.0.0
 */
public enum Message: CustomStringConvertible {
    /// A human readable description for each message type.
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
        case .receivedNothingYet:
            return "No messages have been received so far"
        }
    }

    /// The message sent if a new geo location was captured.
    case capturedLocation(GeoLocation)
    /// The message sent if a new altitude was captured.
    case capturedAltitude(Altitude)
    /// The message sent if a new acceleration was captured.
    case capturedAcceleration(SensorValue)
    /// The message sent if a new rotation was captured.
    case capturedRotation(SensorValue)
    /// The message sent if a new direction was captured.
    case capturedDirection(SensorValue)
    case started(timestamp: Date)
    case stopped(timestamp: Date)
    case paused(timestamp: Date)
    case resumed(timestamp: Date)
    case hasFix
    case fixLost
    case modalityChanged(to: String)
    case receivedNothingYet
}
