/*
 * Copyright 2024 Cyface GmbH
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

import CoreData

/**
 Convert the old `Int64` timestamp to a `Date` for each `GeoLocation`.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 12.0.0
 */
class GeoLocationToGeoLocationPolicy: NSEntityMigrationPolicy {
    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        try super.createDestinationInstances(forSource: sInstance, in: mapping, manager: manager)

        guard let location = manager.destinationInstances(forEntityMappingName: mapping.name, sourceInstances: [sInstance]).first else {
            fatalError("No GeoLocation to migrate was created.")
        }

        guard let timestamp = sInstance.value(forKey: "timestamp") as? Int64 else {
            fatalError("Unable to load old timestamp to migrate to date!")
        }
        let migratedTime = Date(timeIntervalSince1970: Double(timestamp) / 1000.0)

        location.setValue(migratedTime, forKey: "time")
    }
}
