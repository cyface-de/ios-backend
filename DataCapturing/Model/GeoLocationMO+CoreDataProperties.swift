//
//  GeoLocationMO+CoreDataProperties.swift
//  
//
//  Created by Team Cyface on 28.05.19.
//
//

import Foundation
import CoreData


extension GeoLocationMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GeoLocationMO> {
        return NSFetchRequest<GeoLocationMO>(entityName: "GeoLocation")
    }

    @NSManaged public var accuracy: Double
    @NSManaged public var lat: Double
    @NSManaged public var lon: Double
    @NSManaged public var speed: Double
    @NSManaged public var timestamp: Int64
    @NSManaged public var isPartOfCleanedTrack: Bool
    @NSManaged public var track: Track?

}
