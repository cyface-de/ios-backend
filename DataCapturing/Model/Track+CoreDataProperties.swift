//
//  Track+CoreDataProperties.swift
//  
//
//  Created by Team Cyface on 05.03.19.
//
//

import Foundation
import CoreData

extension Track {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Track> {
        return NSFetchRequest<Track>(entityName: "Track")
    }

    @NSManaged public var locations: NSOrderedSet?
    @NSManaged public var measurement: MeasurementMO?

}

// MARK: Generated accessors for locations
extension Track {

    @objc(insertObject:inLocationsAtIndex:)
    @NSManaged public func insertIntoLocations(_ value: GeoLocationMO, at idx: Int)

    @objc(removeObjectFromLocationsAtIndex:)
    @NSManaged public func removeFromLocations(at idx: Int)

    @objc(insertLocations:atIndexes:)
    @NSManaged public func insertIntoLocations(_ values: [GeoLocationMO], at indexes: NSIndexSet)

    @objc(removeLocationsAtIndexes:)
    @NSManaged public func removeFromLocations(at indexes: NSIndexSet)

    @objc(replaceObjectInLocationsAtIndex:withObject:)
    @NSManaged public func replaceLocations(at idx: Int, with value: GeoLocationMO)

    @objc(replaceLocationsAtIndexes:withLocations:)
    @NSManaged public func replaceLocations(at indexes: NSIndexSet, with values: [GeoLocationMO])

    @objc(addLocationsObject:)
    @NSManaged public func addToLocations(_ value: GeoLocationMO)

    @objc(removeLocationsObject:)
    @NSManaged public func removeFromLocations(_ value: GeoLocationMO)

    @objc(addLocations:)
    @NSManaged public func addToLocations(_ values: NSOrderedSet)

    @objc(removeLocations:)
    @NSManaged public func removeFromLocations(_ values: NSOrderedSet)

}
