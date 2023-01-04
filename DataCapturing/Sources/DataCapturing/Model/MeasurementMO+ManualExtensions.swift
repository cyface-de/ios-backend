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
    /// Update this managed object with the property values from a `Measurement`. This might be used for saving the `Measurement` to CoreData.
    /// - throws: On internal CoreData errors, if the `objectId` of this `Measurement` or some part of it are not consistent with CoreData or if the locations captured by the `Measurement` are not strongly monotonically increasing.
    func update(from measurement: Measurement) throws {
        self.synchronizable = measurement.synchronizable
        self.synchronized = measurement.synchronized
        self.trackLength = measurement.trackLength

        guard let context = managedObjectContext else {
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
        }

        // TODO: Delete obsolete events and tracks here. This is not necessary for our current uses cases, but should be added to complete this code conceptually.
    }

}
