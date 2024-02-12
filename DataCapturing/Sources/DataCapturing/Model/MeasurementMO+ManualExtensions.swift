//
//  MeasurementMO+ManualExtensions.swift
//  DataCapturing
//
//  Created by Klemens Muthmann on 14.04.22.
//

import Foundation
import CoreData

/**
 The class extended here is generated during the build process, by CoreData from the data model file.
 */
extension MeasurementMO {
    /// The identifier is actually unsigned, but CoreData is unable to represent this.
    /// Therefore this computed property provides a convenient conversion.
    public var unsignedIdentifier: UInt64 {
        return UInt64(identifier)
    }
    /// Update this managed object with the property values from a `Measurement`. This might be used for saving the `Measurement` to CoreData.
    /// - throws: On internal CoreData errors, if the `objectId` of this `Measurement` or some part of it are not consistent with CoreData or if the locations captured by the `Measurement` are not strongly monotonically increasing.
    func update(from measurement: FinishedMeasurement) throws {
        self.synchronizable = measurement.synchronizable
        self.synchronized = measurement.synchronized

        /*guard let context = managedObjectContext else {
            throw PersistenceError.inconsistentState
        }

        for i in 0..<measurement.tracks.count {
            var track = measurement.tracks[i]

            if let trackObjectId = track.objectId {
                guard let managedTrack = try context.existingObject(with: trackObjectId) as? TrackMO else {
                    throw PersistenceError.dataNotLoadable(measurement: measurement.identifier)
                }
                try managedTrack.update(from: track)
            } else {
                insertIntoTracks(try TrackMO(track: &track, context: context), at: i)
            }
        }

        for i in 0..<measurement.events.count {
            var event = measurement.events[i]

            if let eventObjectId = event.objectId {
                guard let managedEvent = try context.existingObject(with: eventObjectId) as? EventMO else {
                    throw PersistenceError.dataNotLoadable(measurement: measurement.identifier)
                }
                try managedEvent.update(from: event)
            } else {
                insertIntoEvents(try EventMO(event: &event, context: context), at: i)
            }
        }*/

        // TODO: Delete obsolete events and tracks here. This is not necessary for our current uses cases, but should be added to complete this code conceptually.
    }

    /**
     The altitudes in this measurement already cast to the correct type.
     */
    public func typedTracks() -> [TrackMO] {
        guard let typedTracks = tracks?.array as? [TrackMO] else {
            fatalError("Unable to cast tracks to the correct type!")
        }

        return typedTracks
    }

    public func typedEvents() -> [EventMO] {
        guard let typedEvents = events?.array as? [EventMO] else {
            fatalError("Unable to cast events to the correct type!")
        }

        return typedEvents
    }

    public func trackLength() -> Double {
        return typedTracks().map { $0.typedLocations() }.map { locations in
            var prevLocation: GeoLocationMO?
            var ret = 0.0
            locations.forEach { location in
                ret += prevLocation?.distance(to: location) ?? 0.0
                prevLocation = location
            }
            return ret
        }
        .reduce(0.0) { $0 + $1 }
    }
}
