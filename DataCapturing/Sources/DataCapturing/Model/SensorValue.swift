/*
 * Copyright 2018 - 2021 Cyface GmbH
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
 Represents one captured sensor value, such as an acceleration, rotation or direction measurement carried out by the system.

 Such a measurement happens multiple times per second. The `DataCapturingService` stores each of them in one instance of a `SensorValue` until they are saved to persistent storage.

 - SeeAlso: `DataCapturingService`, `PersistenceLayer::save(:[Acceleration]:MeasurementEntity:((MeasurementMO?, Status) -> Void))`

 - Author: Klemens Muthmann
 - Version: 3.1.0
 - Since: 1.0.0
 - Note: This was called  `Acceleration` in previous versions of the SDK.
 */
public class SensorValue: CustomStringConvertible {

    // MARK: - Properties

    /// The time this value was captured at.
    public let timestamp: Date

    /// Value in the device x direction, which is towards the right side if the homebutton faces you.
    public let x: Double

    /// Value in the device y direction, which is towards the top of the device if the homebutton faces you.
    public let y: Double

    /// Value in the device z direction, which is standing on the screen pointing towards you if the homebutton faces you.
    public let z: Double

    /// A human readable description of this object. This is required for debugging purposes.
    public var description: String { return "Sensor Value: (timestamp: \(timestamp), x: \(x), y: \(y), z: \(z))" }

    // MARK: - Initializers

    /**
     The default constructor, which initializes all the properties of a `SensorValue` instance.

     - Parameters:
        - timestamp: The time this value was captured at.
        - x: Value in the device x direction, which is towards the right side if the homebutton faces you.
        - y: Value in the device y direction, which is towards the top of the device if the homebutton faces you.
        - z: value in the device z direction, which is standing on the screen pointing towards you if the homebutton faces you.
     */
    public init(timestamp: Date, x: Double, y: Double, z: Double) {
        self.timestamp = timestamp
        self.x = x
        self.y = y
        self.z = z
    }
}

extension SensorValue: Hashable {
    public static func == (lhs: SensorValue, rhs: SensorValue) -> Bool {
        return lhs.timestamp == rhs.timestamp && lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(timestamp)
        hasher.combine(x)
        hasher.combine(y)
        hasher.combine(z)
    }
}
