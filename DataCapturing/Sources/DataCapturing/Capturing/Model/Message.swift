/*
 * Copyright 2023 Cyface GmbH
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
        case .finished(let time):
            return "Finished measurement at \(time)"
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
    /// Sent after all sensor have stopped capturing data.
    case stopped(timestamp: Date)
    /// A message sent after a measurement was successfully stopped and persistet to permanent storage.
    case finished(timestamp: Date)
    case paused(timestamp: Date)
    case resumed(timestamp: Date)
    case hasFix
    case fixLost
    case modalityChanged(to: String)
    case receivedNothingYet
}

extension Message: Equatable {
    public static func == (lhs: Message, rhs: Message) -> Bool {
        switch (lhs, rhs) {
        case (.capturedLocation(let geoLocationLhs), .capturedLocation(let geoLocationRhs)):
            return geoLocationLhs == geoLocationRhs
        case (.capturedAltitude(let altitudeLhs), .capturedAltitude(let altitudeRhs)):
            return altitudeLhs == altitudeRhs
        case (.capturedAcceleration(let sensorValueLhs), .capturedAcceleration(let sensorValueRhs)):
            return sensorValueLhs == sensorValueRhs
        case (.capturedRotation(let sensorValueLhs), .capturedRotation(let sensorValueRhs)):
            return sensorValueLhs == sensorValueRhs
        case (.capturedDirection(let sensorValueLhs), .capturedDirection(let sensorValueRhs)):
            return sensorValueLhs == sensorValueRhs
        case (.started(let timestampLhs), .started(let timestampRhs)):
            return timestampLhs == timestampRhs
        case (.stopped(let timestampLhs), .stopped(let timestampRhs)):
            return timestampLhs == timestampRhs
        case (.finished(let timestampLhs), .finished(let timestampRhs)):
            return timestampLhs == timestampRhs
        case (.paused(let timestampLhs), .paused(let timestampRhs)):
            return timestampLhs == timestampRhs
        case (.resumed(let timestampLhs), .resumed(let timestampRhs)):
            return timestampLhs == timestampRhs
        case (.hasFix, .hasFix):
            return true
        case (.fixLost, .fixLost):
            return true
        case (.modalityChanged(let toLhs), .modalityChanged(to: let toRhs)):
            return toLhs == toRhs
        case (.receivedNothingYet, .receivedNothingYet):
            return true
        default:
            return false
        }
    }
}
