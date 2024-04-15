/*
 * Copyright 2022-2024 Cyface GmbH
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
 An enumeration of all the possible errors thrown during serialization.

 - Author: Klemens Muthmann
 - Version: 2.0.0
 - Since: 1.0.0
 */
public enum SerializationError: Error {
    /// Thrown if compression of serialized data was not successful. The failed data is provided as parameter.
    case compressionFailed(data: Data)
    /// Thrown if the system was unable to serialize a timestamp.
    case nonSerializableSensorValueTimestamp(cause: Error, timestamp: Date)
    /// Thrown if serializing an X sensor value failed.
    case nonSerializableXValue(cause: Error, value: Double)
    /// Thrown if serializing a Y sensor value failed.
    case nonSerializableYValue(cause: Error, value: Double)
    /// Thrown if serializing a Z sensor value failed.
    case nonSerializableZValue(cause: Error, value: Double)
    /// Thrown if serializing a location timestamp failed.
    case nonSerializableLocationTimestamp(cause: Error, timestamp: UInt64)
    /// Thrown if serializing an accuracy value failed.
    case nonSerializableAccuracy(cause: Error, accuracy: Double)
    /// Thrown if serializing a speed value failed.
    case nonSerializableSpeed(cause: Error, speed: Double)
    /// Thrown if serializing a latitude value failed.
    case nonSerializableLatitude(cause: Error, latitude: Double)
    /// Thrown if serializing a longitude value failed.
    case nonSerializableLongitude(cause: Error, longitude: Double)
}

extension SerializationError: LocalizedError {
    /// The internationalized error description providing further details about a thrown error.
    public var errorDescription: String? {
        switch self {
        case .compressionFailed(data: let data):
            let errorMessage =  NSLocalizedString(
                "de.cyface.error.SerializationError.compressionFailed",
                value: "Compression of %d bytes failed!",
                comment: """
Tell the user that compression of captured data for transmission to the Cyface Server has failed! \
The number of bytes that failed to serialize is provided as the first argument.
""")
            return String.localizedStringWithFormat(errorMessage, data.count)
        case .nonSerializableSensorValueTimestamp(cause: let cause, timestamp: let timestamp):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.SerializationError.nonSerializableSensorValueTimestamp",
                value: "Failed to serialize timestamp %d due to:\n %@",
                comment: """
Tell the user that serialization of data failed because a timestamp had the wrong format! \
The timestamp is provided as the first parameter and the causing error as the second.
""")
            return String.localizedStringWithFormat(errorMessage, timestamp.timeIntervalSince1970, cause.localizedDescription)
        case .nonSerializableXValue(cause: let cause, value: let value):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.SerializationError.nonSerializableXValue",
                value: "Failed to serialize x sensor value %d due to:\n %@",
                comment: """
Tell the user that serialization of an x sensor value has failed! \
The value is provided as the first parameter and the causing error as the second.
""")
            return String.localizedStringWithFormat(errorMessage, value, cause.localizedDescription)
        case .nonSerializableYValue(cause: let cause, value: let value):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.SerializationError.nonSerializableYValue",
                value: "Failed to serialize y sensor value %d due to:\n %@",
                comment: """
Tell the user that serialization of a y sensor value has failed! \
The value is provided as the first parameter and the causing error as the second.
""")
            return String.localizedStringWithFormat(errorMessage, value, cause.localizedDescription)
        case .nonSerializableZValue(cause: let cause, value: let value):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.SerializationError.nonSerializableZValue",
                value: "Failed to serialize z sensor value %d due to:\n %@",
                comment: """
Tell the user that serialization of a z sensor value has failed! \
The value is provided as the first parameter and the causing error as the second.
""")
            return String.localizedStringWithFormat(errorMessage, value, cause.localizedDescription)
        case .nonSerializableLocationTimestamp(cause: let cause, timestamp: let timestamp):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.SerializationError.nonSerializableLocationTimestamp",
                value: "Failed to serialize location timestamp %d due to:\n %@",
                comment: """
Tell the user that serialization of a location timestamp has failed! \
The location timestamp is provided as the first parameter and the causing error as the second.
""")
            return String.localizedStringWithFormat(errorMessage, timestamp, cause.localizedDescription)
        case .nonSerializableAccuracy(cause: let cause, accuracy: let accuracy):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.SerializationError.nonSerializableAccuracy",
                value: "Failed to serialize accuracy %d due to:\n %@",
                comment: """
Tell the user that serialization of an accuracy has failed! \
The accuracy is provided as the first parameter and the causing error as the second.
""")
            return String.localizedStringWithFormat(errorMessage, accuracy, cause.localizedDescription)
        case .nonSerializableSpeed(cause: let cause, speed: let speed):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.SerializationError.nonSerializableSpeed",
                value: "Failed to serialize x sensor value %d due to:\n %@",
                comment: """
Tell the user that serialization of a speed has failed! \
The speed is provided as the first parameter and the causing error as the second.
""")
            return String.localizedStringWithFormat(errorMessage, speed, cause.localizedDescription)
        case .nonSerializableLatitude(cause: let cause, latitude: let latitude):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.SerializationError.nonSerializableLatitude",
                value: "Failed to serialize latitude %d due to:\n %@",
                comment: """
Tell the user that serialization of a latitude has failed! \
The latitude is provided as the first parameter and the causing error as the second.
""")
            return String.localizedStringWithFormat(errorMessage, latitude, cause.localizedDescription)
        case .nonSerializableLongitude(cause: let cause, longitude: let longitude):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.SerializationError.nonSerializableLongitude",
                value: "Failed to serialize longitude %d due to:\n %@",
                comment: """
Tell the user that serialization of an longitude has failed! \
The longitude is provided as the first parameter and the causing error as the second.
""")
            return String.localizedStringWithFormat(errorMessage, longitude, cause.localizedDescription)
        }
    }
}
