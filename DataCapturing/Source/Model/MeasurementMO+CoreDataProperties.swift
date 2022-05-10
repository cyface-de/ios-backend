/*
* Copyright 2019 Cyface GmbH
*
* This file is part of the Cyface SDK for iOS.
*
* The Cyface SDK for iOS is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* The Cyface SDK for iOS is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with the Cyface SDK for iOS. If not, see <http://www.gnu.org/licenses/>.
*/

import Foundation
import CoreData

extension MeasurementMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MeasurementMO> {
        return NSFetchRequest<MeasurementMO>(entityName: "Measurement")
    }

    @NSManaged public var accelerationsCount: Int32
    @NSManaged public var rotationsCount: Int32
    @NSManaged public var directionsCount: Int32
    @NSManaged public var identifier: Int64
    @NSManaged public var synchronizable: Bool
    @NSManaged public var synchronized: Bool
    @NSManaged public var timestamp: Int64
    @NSManaged public var trackLength: Double
    @NSManaged public var events: NSOrderedSet?
    @NSManaged public var tracks: NSOrderedSet?

}

// MARK: Generated accessors for events
extension MeasurementMO {

    @objc(insertObject:inEventsAtIndex:)
    @NSManaged public func insertIntoEvents(_ value: EventMO, at idx: Int)

    @objc(removeObjectFromEventsAtIndex:)
    @NSManaged public func removeFromEvents(at idx: Int)

    @objc(insertEvents:atIndexes:)
    @NSManaged public func insertIntoEvents(_ values: [EventMO], at indexes: NSIndexSet)

    @objc(removeEventsAtIndexes:)
    @NSManaged public func removeFromEvents(at indexes: NSIndexSet)

    @objc(replaceObjectInEventsAtIndex:withObject:)
    @NSManaged public func replaceEvents(at idx: Int, with value: EventMO)

    @objc(replaceEventsAtIndexes:withEvents:)
    @NSManaged public func replaceEvents(at indexes: NSIndexSet, with values: [EventMO])

    @objc(addEventsObject:)
    @NSManaged public func addToEvents(_ value: EventMO)

    @objc(removeEventsObject:)
    @NSManaged public func removeFromEvents(_ value: EventMO)

    @objc(addEvents:)
    @NSManaged public func addToEvents(_ values: NSOrderedSet)

    @objc(removeEvents:)
    @NSManaged public func removeFromEvents(_ values: NSOrderedSet)

}

// MARK: Generated accessors for tracks
extension MeasurementMO {

    @objc(insertObject:inTracksAtIndex:)
    @NSManaged public func insertIntoTracks(_ value: TrackMO, at idx: Int)

    @objc(removeObjectFromTracksAtIndex:)
    @NSManaged public func removeFromTracks(at idx: Int)

    @objc(insertTracks:atIndexes:)
    @NSManaged public func insertIntoTracks(_ values: [TrackMO], at indexes: NSIndexSet)

    @objc(removeTracksAtIndexes:)
    @NSManaged public func removeFromTracks(at indexes: NSIndexSet)

    @objc(replaceObjectInTracksAtIndex:withObject:)
    @NSManaged public func replaceTracks(at idx: Int, with value: TrackMO)

    @objc(replaceTracksAtIndexes:withTracks:)
    @NSManaged public func replaceTracks(at indexes: NSIndexSet, with values: [TrackMO])

    @objc(addTracksObject:)
    @NSManaged public func addToTracks(_ value: TrackMO)

    @objc(removeTracksObject:)
    @NSManaged public func removeFromTracks(_ value: TrackMO)

    @objc(addTracks:)
    @NSManaged public func addToTracks(_ values: NSOrderedSet)

    @objc(removeTracks:)
    @NSManaged public func removeFromTracks(_ values: NSOrderedSet)

}
