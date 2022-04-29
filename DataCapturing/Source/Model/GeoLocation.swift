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
import CoreData

/**
 One geo location measurement provided by the system.

 Each measurement received by the `DataCapturingService` leads to the creation of one `GeoLocation` instance. They are kept in memory until saved to persistent storage.

 - Remark: DO NOT confuse this class with *CoreData* generated model object `GeoLocationMO`. Since the model object is not thread safe you should use an instance of this class if you hand data between processes.
 - SeeAlso: `DataCapturingService`, `PersistenceLayer.save(:[GeoLocation]:MeasurementEntity:(MeasurementMO?, Status) -> Void)`, `GeoLocationMO`

 - Author: Klemens Muthmann
 - Version: 1.1.0
 - Since: 1.0.0
 */
public class GeoLocation: CustomStringConvertible {

    // MARK: - Properties
    var objectId: NSManagedObjectID?
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
    public let track: Track
    /// A human readable description of this object.
    public var description: String {
        return "GeoLocation (latitude: \(latitude), longitude: \(longitude), accuracy: \(accuracy), speed: \(speed), timestamp: \(timestamp))"
    }

    convenience init(managedObject: GeoLocationMO, parent: Track) throws {
        try self.init(
            latitude: managedObject.lat,
            longitude: managedObject.lon,
            accuracy: managedObject.accuracy,
            speed: managedObject.speed,
            timestamp: managedObject.timestamp,
            isValid: managedObject.isPartOfCleanedTrack,
            parent: parent)
        self.objectId = managedObject.objectID
    }

    // TODO parent sollte sich selbst darum kümmern, dass eine Location hinzugefügt wird.
    public init(latitude: Double, longitude: Double, accuracy: Double, speed: Double, timestamp: Int64, isValid: Bool = true, parent: Track) throws {
        self.latitude = latitude
        self.longitude = longitude
        self.accuracy = accuracy
        self.speed = speed
        self.timestamp = timestamp
        self.isValid = isValid
        self.track = parent
    }
}
