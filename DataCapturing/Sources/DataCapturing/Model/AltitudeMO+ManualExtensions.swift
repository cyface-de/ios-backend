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
    convenience init(altitude: Altitude, context: NSManagedObjectContext) {
        self.init(context: context)

        update(from: altitude)
    }

    func update(from altitude: Altitude) {
        self.time = altitude.time
        self.altitude = altitude.relativeAltitude
    }
}
