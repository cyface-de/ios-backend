//
//  Event+CoreDataProperties.swift
//  DataCapturing
//
//  Created by Team Cyface on 24.07.19.
//  Copyright © 2019 Cyface GmbH. All rights reserved.
//
//

import Foundation
import CoreData

extension Event {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Event> {
        return NSFetchRequest<Event>(entityName: "Event")
    }

    @NSManaged public var time: NSDate?
    @NSManaged public var type: Int16
    @NSManaged public var measurement: MeasurementMO?

    var typeEnum: EventType {
        get {
            return EventType(rawValue: type)!;
        }
        set {
            self.type = newValue.rawValue
        }
    }
}
