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
import CoreData

extension EventMO {

    /// Translates between the enumeration fo `EventType` and the database representation.
    public var typeEnum: EventType {
        get {
            return EventType(rawValue: type)!
        }
        set {
            self.type = newValue.rawValue
        }
    }

    /**
     An initializer used to create an event managed object from a regular `Event` instance.

     This also refreshes the provided events `objectId` to this newly created managed objects objectId.

     - Parameters:
        - event: The `Event` used to populate this new managed object.
        - context: The `NSManagedObjectContext` to store the managed object to.
     */
    convenience init(event: inout Event, context: NSManagedObjectContext) throws {
        self.init(context: context)
        event.objectId = self.objectID

        try update(from: event)
    }

    /**
     Refreshes this managed object with the values from the provided `Event`.

     This can for example be used to store the update managed object afterwards with a call to `context.save()`.

     - Parameter event: The `Event` to refresh this managed object from.
     - Throws PersistenceError.unsynchronizedMeasurement: If the parent measurement of the `Event` is not stored in the database.
     - Throws PersistenceError.inconsistentState: If there is no `NSManagedObjectContext` associated with this managed object.
     - Throws PersistenceError.measurementNotLoadable: If the parent measurement could not be retrieved from the database.
     */
    func update(from event: Event) throws {
        self.type = event.type.rawValue
        self.time = event.time as NSDate
        self.value = event.value

        guard let managedParentObjectId = event.measurement.objectId else {
            throw PersistenceError.unsynchronizedMeasurement(identifier: event.measurement.identifier)
        }

        guard let context = managedObjectContext else {
            throw PersistenceError.inconsistentState
        }

        guard let managedParent = try context.existingObject(with: managedParentObjectId) as? MeasurementMO else {
            throw PersistenceError.measurementNotLoadable(event.measurement.identifier)
        }

        self.measurement = managedParent
    }
}
