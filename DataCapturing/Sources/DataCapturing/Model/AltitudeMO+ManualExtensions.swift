//
//  File.swift
//  
//
//  Created by Klemens Muthmann on 12.04.23.
//

import Foundation
import CoreData

extension AltitudeMO {
    /// Initialize a CoreData managed track object from the properties of a `Track`.
    convenience init(altitude: inout Altitude, context: NSManagedObjectContext) throws {
        self.init(context: context)
        altitude.objectId = self.objectID

        try update(from: altitude)
    }

    func update(from altitude: Altitude) throws {
        guard altitude.objectId == self.objectID else {
            throw PersistenceError.inconsistentState
        }

        self.time = altitude.time
        self.altitude = altitude.relativeAltitude
    }
}
