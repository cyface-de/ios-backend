/*
 * Copyright 2018 Cyface GmbH
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
 One geo location measurement provided by the system.

 Each measurement received by the `DataCapturingService` leads to the creation of one `GeoLocation` instance. They are kept in memory until saved to persistent storage.

 - Remark: DO NOT confuse this class with *CoreData* generated model object `GeoLocationMO`. Since the model object is not thread safe you should use an instance of this class if you hand data between processes.
 - SeeAlso: `DataCapturingService`, `PersistenceLayer.save(:[GeoLocation]:MeasurementEntity:(MeasurementMO?, Status) -> Void)`, `GeoLocationMO`

 - Author: Klemens Muthmann
 - Version: 1.1.0
 - Since: 1.0.0
 */
public struct GeoLocation: CustomStringConvertible {

    // MARK: - Properties

    /// The locations latitude coordinate as a value from -90.0 to 90.0 in south and north diretion.
    public let latitude: Double
    /// The locations longitude coordinate as a value from -180.0 to 180.0 in west and east direction.
    public let longitude: Double
    /// The estimated accuracy of the measurement in meters.
    public let accuracy: Double
    /// The speed the device was moving during the measurement in meters per second.
    public let speed: Double
    /// The time the measurement happened at in milliseconds since the 1st of january 1970.
    public let timestamp: Int64
    /// Whether or not this is a valid location in a cleaned track.
    public let isValid: Bool
    /// A human readable description of this object.
    public var description: String {
        return "GeoLocation (latitude: \(latitude), longitude: \(longitude), accuracy: \(accuracy), speed: \(speed), timestamp: \(timestamp))"
    }

    public init(latitude: Double, longitude: Double, accuracy: Double, speed: Double, timestamp: Int64, isValid: Bool = true) {
        self.latitude = latitude
        self.longitude = longitude
        self.accuracy = accuracy
        self.speed = speed
        self.timestamp = timestamp
        self.isValid = isValid
    }
}
