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
}
