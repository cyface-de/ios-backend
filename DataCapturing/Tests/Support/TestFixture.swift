//
//  TestFixture.swift
//  DataCapturing-Unit-Tests
//
//  Created by Klemens Muthmann on 21.04.22.
//

import Foundation
import CoreMotion
@testable import DataCapturing

struct TestFixture {
    /**
     Create fixture data to use during testing

     - Parameters:
        - latitude: The locations latitude coordinate as a value from -90.0 to 90.0 in south and north diretion
        - longitude: The locations longitude coordinate as a value from -180.0 to 180.0 in west and east direction
        - accuracy: The estimated accuracy of the measurement in meters
        - speed: The speed the device was moving during the measurement in meters per second
        - timestamp: The time the measurement happened at in milliseconds since the 1st of january 1970
        - isValid: Whether or not this is a valid location in a cleaned track
     */
    static func location(latitude: Double = 2.0, longitude: Double = 2.0, accuracy: Double = 1.0, speed: Double = 10.0, timestamp: Date = Date(), isValid: Bool = true) -> LocationCacheEntry {
        return LocationCacheEntry(latitude: latitude, longitude: longitude, accuracy: accuracy, speed: speed, timestamp: timestamp, isValid: isValid)
    }

    static func randomLocation(timestamp: Date = Date()) -> LocationCacheEntry {
        return LocationCacheEntry(latitude: Double.random(in: -90.0 ... 90.0), longitude: Double.random(in: 0.0 ..< 360.0), accuracy: Double.random(in: 2.0 ... 15.0), speed: Double.random(in: 0.0 ... 10.0), timestamp: timestamp, isValid: true)
    }

    /**
     Create fixture acceleration
     */
    static func acceleration() -> SensorValue {
        return SensorValue(timestamp: Date(), x: 1.0, y: 1.0, z: 1.0)
    }

    static func randomAcceleration() -> SensorValue {
        return SensorValue(timestamp: Date(timeIntervalSince1970: TimeInterval(Double.random(in: 0.0 ... 1571302762.0))), x: Double.random(in: 0.0 ... 40.0), y: Double.random(in: 0.0 ... 40.0), z: Double.random(in: 0.0 ... 40.0))
    }
}
