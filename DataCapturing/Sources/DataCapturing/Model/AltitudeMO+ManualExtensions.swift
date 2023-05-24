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

        try update(from: altitude)
    }

    func update(from altitude: Altitude) throws {
        self.time = altitude.time
        self.altitude = altitude.relativeAltitude
    }
}
