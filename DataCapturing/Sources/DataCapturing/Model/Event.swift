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
 - Version 2.0.0
 - since: 11.0.0
 */
public struct Event: CustomStringConvertible {
    /// The time the event occured at.
    public let time: Date
    /// The type of the event.
    public let type: EventType
    /// An optional value if that is necessary.
    public var value: String?

    /**
     An initializer, creating a new `Event` from a database managed object.

     - Parameters:
            - managedObject: The managed event object used to populate the new `Event` instance.
     */
    init(managedObject: EventMO) {
        guard let managedObjectTimeAsDate = managedObject.time else {
            fatalError()
        }
        self.init(time: managedObjectTimeAsDate, type: managedObject.typeEnum, value: managedObject.value)
    }

    /**
Creates a new but not yet persisted object of this class.

If this instance is persisted via CoreData, its `objectId` must be set to the appropriate value, mirroring the `objectID` of the corresponding managed object.

- Parameters:
     - time: The time the event occured at.
     - type: The type of the event.
     - value: An optional value if that is necessary.
     */
    public init(time: Date=Date(), type: EventType, value: String?=nil) {
        self.time = time
        self.type = type
        self.value = value
    }

   /// A stringified variant of this object. Mostly used to pretty print instances during debugging.
    public var description: String {
        "Event(type: \(type), time: \(time), value: \(String(describing: value)))"
    }
}
