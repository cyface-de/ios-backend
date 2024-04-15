/*
 * Copyright 2018-2024 Cyface GmbH
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

import CoreLocation

/**
 One geo location measurement provided by the system.

 Each measurement received by the `DataCapturingService` leads to the creation of one `GeoLocation` instance. They are kept in memory until saved to persistent storage.

 - Remark: DO NOT confuse this class with *CoreData* generated model object `GeoLocationMO`. Since the model object is not thread safe you should use an instance of this class if you hand data between processes.
 - SeeAlso: `DataCapturingService`, `PersistenceLayer.save(:[GeoLocation]:MeasurementEntity:(MeasurementMO?, Status) -> Void)`, `GeoLocationMO`

 - Author: Klemens Muthmann
 - Version: 3.0.0
 - Since: 1.0.0
 */
public class GeoLocation: CustomStringConvertible {

    // MARK: - Properties
    /// The locations latitude coordinate as a value from -90.0 to 90.0 in south and north direction.
    public let latitude: Double
    /// The locations longitude coordinate as a value from -180.0 to 180.0 in west and east direction.
    public let longitude: Double
    /// The estimated accuracy of the measurement in meters.
    public let accuracy: Double
    /// The speed the device was moving during the measurement in meters per second.
    public let speed: Double
    /// The time the measurement happened.
    public let time: Date
    /// The height change in meters in comparison to the last measured location.
    public let altitude: Double
    /// The accuracy of the heigt informatio as provided by the geo location sensor.
    public let verticalAccuracy: Double
    /// A human readable description of this object.
    public var description: String {
        return "GeoLocation (latitude: \(latitude), longitude: \(longitude), accuracy: \(accuracy), speed: \(speed), timestamp: \(time.debugDescription))"
    }

    /**
     Creates a new `GeoLocation` from a CoreData managed object.

     - Parameters
        - managedObject: The CoreData managed object to populate this object from.
     */
    convenience init(managedObject: GeoLocationMO) {
        self.init(
            latitude: managedObject.lat,
            longitude: managedObject.lon,
            accuracy: managedObject.accuracy,
            speed: managedObject.speed,
            time: managedObject.time!,
            altitude: managedObject.altitude,
            verticalAccuracy: managedObject.verticalAccuracy
        )
    }

    /**
     Creates a new `GeoLocation` with all the values set individually.

     After creation you must add this new object to the parent, via `append`.

     - Parameters:
        - latitude: The locations latitude coordinate as a value from -90.0 to 90.0 in south and north direction.
        - longitude: The locations longitude coordinate as a value from -180.0 to 180.0 in west and east direction.
        - accuracy: The estimated accuracy of the measurement in meters.
        - speed: The speed the device was moving during the measurement in meters per second.
        - time: The time the measurement happened.
        - altitude: The height change in meters in comparison to the last measured location.
        - verticalAccuracy: The accuracy of the heigt informatio as provided by the geo location sensor.
     */
    public init(
        latitude: Double,
        longitude: Double,
        accuracy: Double,
        speed: Double,
        time: Date,
        altitude: Double,
        verticalAccuracy: Double
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.accuracy = accuracy
        self.speed = speed
        self.time = time
        self.altitude = altitude
        self.verticalAccuracy = verticalAccuracy
    }

    public func distance(from previousLocation: CLLocation) -> Double {
        let clLocation = CLLocation(latitude: latitude, longitude: longitude)
        return clLocation.distance(from: previousLocation)
    }

    public func distance(from previousLocation: GeoLocationMO) -> Double {
        let previousCLLocation = CLLocation(latitude: previousLocation.lat, longitude: previousLocation.lon)
        return distance(from: previousCLLocation)
    }

    public func distance(from previousLocationLatLonCoordinates: (Double, Double)) -> Double {
        return distance(from: CLLocation(
            latitude: previousLocationLatLonCoordinates.0,
            longitude: previousLocationLatLonCoordinates.1))
    }

    public func distance(from previousLocation: GeoLocation) -> Double {
        return distance(from: CLLocation(latitude: previousLocation.latitude, longitude: previousLocation.longitude))
    }
}

extension GeoLocation: Equatable {
    public static func == (lhs: GeoLocation, rhs: GeoLocation) -> Bool {
        if lhs === rhs {
            return true
        } else {
            return lhs.latitude.equal(rhs.latitude, precise: 6) && 
            lhs.longitude.equal(rhs.longitude, precise: 6) &&
            lhs.speed.equal(rhs.speed, precise: 2) &&
            lhs.accuracy.equal(rhs.accuracy, precise: 3) &&
            lhs.time == rhs.time &&
            lhs.altitude.equal(rhs.altitude, precise: 3) &&
            lhs.verticalAccuracy.equal(rhs.verticalAccuracy, precise: 3)
        }
    }
}
