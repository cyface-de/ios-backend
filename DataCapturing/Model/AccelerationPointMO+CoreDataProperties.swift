//
//  AccelerationPointMO+CoreDataProperties.swift
//  
//
//  Created by Team Cyface on 04.12.17.
//
//

import Foundation
import CoreData

extension AccelerationPointMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AccelerationPointMO> {
        return NSFetchRequest<AccelerationPointMO>(entityName: "AccelerationPoint")
    }

    @NSManaged public var ax: Double
    @NSManaged public var ay: Double
    @NSManaged public var az: Double
    @NSManaged public var timestamp: Int64

}
