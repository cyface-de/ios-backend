//
//  GeoLocationMO+CoreDataProperties.swift
//  
//
//  Created by Team Cyface on 04.12.17.
//
//

import Foundation
import CoreData

extension GeoLocationMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GeoLocationMO> {
        return NSFetchRequest<GeoLocationMO>(entityName: "GeoLocation")
    }

    // MARK: Properties
    /**
     The captured latitude of this `GeoLocation` in decimal coordinates as a value between -90.0 (south pole) and 90.0 (north pole).
     */
    @NSManaged public var lat: Double
    /**
     The captured longitude of this `GeoLocation` in decimal coordinates as a value between -180.0 and 180.0.
     */
    @NSManaged public var lon: Double
    /**
     The current speed fo the measuring device according to its location sensor in meters per second.  iOS sets this to a negative value if speed is very low or invalid.
     */
    @NSManaged public var speed: Double
    /**
     The current accuracy of the measuring device in meters.
     */
    @NSManaged public var accuracy: Double
    /**
     The time this location was captured as UTC timestamp (milliseconds since january 1st 1970 00:00:00).
     */
    @NSManaged public var timestamp: Int64

}
