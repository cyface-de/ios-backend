/*
* Copyright 2022 Cyface GmbH
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
import CoreMotion
@testable import DataCapturing

/**
 Helper to create test fixture data.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - since: 11.0.0
 */
struct TestFixture {
    /**
     Create fixture data to use during testing

     - Parameters:
        - latitude: The locations latitude coordinate as a value from -90.0 to 90.0 in south and north diretion
        - longitude: The locations longitude coordinate as a value from -180.0 to 180.0 in west and east direction
        - altitude: The number of meters above sea level.
        - accuracy: The estimated accuracy of the measurement in meters
        - verticalAccuracy: The accuracy of the altitude provided by the geo location sensor in meters. This means that it is 68% likely that the real altitude value is between + or - this amount of meters from the reported value.
        - speed: The speed the device was moving during the measurement in meters per second
        - timestamp: The time the measurement happened at in milliseconds since the 1st of january 1970
        - isValid: Whether or not this is a valid location in a cleaned track
     */
    static func location(latitude: Double = 2.0, longitude: Double = 2.0, altitude: Double = 5.0, accuracy: Double = 1.0, verticalAccuracy: Double = 3.0, speed: Double = 10.0, timestamp: Date = Date(), isValid: Bool = true) -> LocationCacheEntry {
        return LocationCacheEntry(latitude: latitude, longitude: longitude, altitude: altitude, accuracy: accuracy, verticalAccuracy: verticalAccuracy, speed: speed, timestamp: timestamp, isValid: isValid)
    }

    /// Create a random `LocationCacheEntry` with a fixed timestamp. If that entry should be added to a measurement, make sure that the timestamp is strong monotonically increasing.
    static func randomLocation(timestamp: Date = Date()) -> LocationCacheEntry {
        return LocationCacheEntry(latitude: Double.random(in: -90.0 ... 90.0), longitude: Double.random(in: 0.0 ..< 360.0), altitude: Double.random(in: 0.0...8000.0), accuracy: Double.random(in: 2.0 ... 15.0), verticalAccuracy: Double.random(in: 1.0...10.0), speed: Double.random(in: 0.0 ... 10.0), timestamp: timestamp, isValid: true)
    }

    /**
     Create fixture acceleration with fixed values.
     */
    static func acceleration() -> SensorValue {
        return SensorValue(timestamp: Date(), x: 1.0, y: 1.0, z: 1.0)
    }

    /// Create fixture acceleration with random values. This is for example important if accurate compression is an issue for your test.
    static func randomAcceleration() -> SensorValue {
        return SensorValue(timestamp: Date(timeIntervalSince1970: TimeInterval(Double.random(in: 0.0 ... 1571302762.0))), x: Double.random(in: 0.0 ... 40.0), y: Double.random(in: 0.0 ... 40.0), z: Double.random(in: 0.0 ... 40.0))
    }
}