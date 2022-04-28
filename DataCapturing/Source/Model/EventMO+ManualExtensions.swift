//
//  EventMO+ManualExtensions.swift
//  DataCapturing
//
//  Created by Klemens Muthmann on 13.04.22.
//

import Foundation
import CoreData

extension EventMO {

    public var typeEnum: EventType {
        get {
            return EventType(rawValue: type)!
        }
        set {
            self.type = newValue.rawValue
        }
    }

    convenience init(event: inout Event, context: NSManagedObjectContext) throws {
        self.init(context: context)
        event.objectId = self.objectID

        try update(from: event)
    }

    func update(from event: Event) throws {
        self.type = event.type.rawValue
        self.time = event.time as NSDate
        self.value = event.value

        guard let managedParentObjectId = event.measurement.objectId else {
            throw PersistenceError.inconsistentState
        }

        guard let context = managedObjectContext else {
            throw PersistenceError.inconsistentState
        }

        guard let managedParent = try context.existingObject(with: managedParentObjectId) as? MeasurementMO else {
            throw PersistenceError.inconsistentState
        }

        self.measurement = managedParent
    }
}
