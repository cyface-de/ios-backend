//
//  Event+CoreDataProperties.swift
//  
//
//  Created by Team Cyface on 14.09.19.
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
    @NSManaged public var value: String?
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
