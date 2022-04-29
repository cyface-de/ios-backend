//
//  Event.swift
//  DataCapturing
//
//  Created by Klemens Muthmann on 13.04.22.
//

import Foundation
import CoreData

public class Event: CustomStringConvertible {
    var objectId: NSManagedObjectID?
    public let time: Date
    public let type: EventType
    public var value: String?
    public let measurement: Measurement

    convenience init(managedObject: EventMO, parent: Measurement) {
        guard let managedObjectTimeAsDate = managedObject.time as? Date else {
            fatalError()
        }
        self.init(time: managedObjectTimeAsDate, type: managedObject.typeEnum, value: managedObject.value, measurement: parent)
        self.objectId = managedObject.objectID
    }

    init(time: Date=Date(), type: EventType, value: String?=nil, measurement: Measurement) {
        self.time = time
        self.type = type
        self.value = value
        self.measurement = measurement
    }

    public var description: String {
        "Event(type: \(type), time: \(time), value: \(value), measurement: \(measurement.identifier))"
    }
}
