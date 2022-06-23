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

/**
A single user initiated event during the capturing of a `Measurement`.

 - Author: Klemens Muthmann
 - Version 1.0.0
 - since: 11.0.0
 */
public class Event: CustomStringConvertible {
    /// The database identifier of the event or `nil` if the event has not been saved yet.
    var objectId: NSManagedObjectID?
    /// The time the event occured at.
    public let time: Date
    /// The type of the event.
    public let type: EventType
    /// An optional value if that is necessary.
    public var value: String?
    /// The `Measurement` during which the event occured.
    public let measurement: Measurement

    /**
     An initializer, creating a new `Event` from a database managed object.

     After a call to this initializer, the `objectId` will be set to the provied `managedObject` objectId.

     - Parameters:
            - managedObject: The managed event object used to populate the new `Event` instance.
            - parent: The `Measurement` this event should be added to.
     - Attention: CoreData changes the objectId as soon as a new instance is written from the `NSManagedObjectContext` to the underlying database. So if you call `context.save()` after this contrxutor, the objectId might become invalid. Loading the object from the database prior to its usage provides a save instance.
     */
    convenience init(managedObject: EventMO, parent: Measurement) {
        guard let managedObjectTimeAsDate = managedObject.time as? Date else {
            fatalError()
        }
        self.init(time: managedObjectTimeAsDate, type: managedObject.typeEnum, value: managedObject.value, measurement: parent)
        self.objectId = managedObject.objectID
    }

    /**
Creates a new but not yet persisted object of this class.

If this instance is persisted via CoreData, its `objectId` must be set to the appropriate value, mirroring the `objectID` of the corresponding managed object.

- Parameters:
     - time: The time the event occured at.
     - type: The type of the event.
     - value: An optional value if that is necessary.
     - measurement: The `Measurement` during which the event occured.
     */
    init(time: Date=Date(), type: EventType, value: String?=nil, measurement: Measurement) {
        self.time = time
        self.type = type
        self.value = value
        self.measurement = measurement
    }

   /// A stringified variant of this object. Mostly used to pretty print instances during debugging.
    public var description: String {
        "Event(type: \(type), time: \(time), value: \(value), measurement: \(measurement.identifier))"
    }
}
