/*
 * Copyright 2019 Cyface GmbH
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
 Transforms the transporation mode, saved inside the measurement up to version 7 into an events as required by the model starting with version 8.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 5.0.0
 */
class MeasurementContextToEventPolicy: NSEntityMigrationPolicy {
    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        try super.createDestinationInstances(forSource: sInstance, in: mapping, manager: manager)

        guard let rawContextValue = sInstance.value(forKey: "context") as? String else {
            fatalError("Unable to load context for measurement!")
        }

        guard let measurementTimestamp = sInstance.value(forKey: "timestamp") as? Int64 else {
            fatalError("Unable to load timestamp from source measurement!")
        }

        let event = NSEntityDescription.insertNewObject(forEntityName: "Event", into: manager.destinationContext)
        event.setValue(4, forKey: "type")
        event.setValue(Date(timeIntervalSince1970: TimeInterval(integerLiteral: measurementTimestamp / Int64(1_000))), forKey: "time")
        event.setValue(rawContextValue, forKey: "value")
    }

    override func createRelationships(forDestination dInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        try super.createRelationships(forDestination: dInstance, in: mapping, manager: manager)

        let eventsFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Event")
        let eventFetchRequestPredicate = NSPredicate(format: "measurement == %@", dInstance)
        eventsFetchRequest.predicate = eventFetchRequestPredicate
        guard let events = try dInstance.managedObjectContext?.fetch(eventsFetchRequest) else {
            fatalError()
        }
        dInstance.setValue(NSOrderedSet(array: events), forKey: "events")
    }
}
