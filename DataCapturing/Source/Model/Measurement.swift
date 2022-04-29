//
//  Measurement.swift
//  DataCapturing
//
//  Created by Klemens Muthmann on 13.04.22.
//

import Foundation
import CoreData

public class Measurement: Hashable, Equatable {
    var objectId: NSManagedObjectID?
    public var accelerationsCount: Int32
    public var rotationsCount: Int32
    public var directionsCount: Int32
    public let identifier: Int64
    public var synchronizable: Bool
    public var synchronized: Bool
    public let timestamp: Int64
    public var trackLength: Double
    public var events: [Event]
    public var tracks: [Track]

    convenience init(managedObject: MeasurementMO) throws {
        self.init(
            identifier: managedObject.identifier,
            synchronizable: managedObject.synchronizable,
            synchronized: managedObject.synchronized,
            accelerationsCount: managedObject.accelerationsCount,
            rotationsCount: managedObject.rotationsCount,
            directionsCount: managedObject.directionsCount,
            timestamp: managedObject.timestamp,
            trackLength: managedObject.trackLength)
        self.objectId = managedObject.objectID

        if let eventMOs = managedObject.events?.array as? [EventMO] {

            for eventMO in eventMOs {
                let event = Event(managedObject: eventMO, parent: self)
                events.append(event)
            }
        }

        if let trackMOs = managedObject.tracks?.array as? [TrackMO] {
            for trackMO in trackMOs {
                let track = try Track(managedObject: trackMO, parent: self)
                tracks.append(track)
            }
        }
    }

    init(identifier: Int64, synchronizable: Bool = false, synchronized: Bool = false, accelerationsCount: Int32 = 0, rotationsCount: Int32 = 0, directionsCount: Int32 = 0, timestamp: Int64 = DataCapturingService.currentTimeInMillisSince1970(), trackLength: Double = 0.0, events: [Event] = [Event](), tracks: [Track] = [Track]()) {
        self.identifier = identifier
        self.synchronizable = synchronizable
        self.synchronized = synchronized
        self.accelerationsCount = accelerationsCount
        self.rotationsCount = rotationsCount
        self.directionsCount = directionsCount
        self.timestamp = timestamp
        self.trackLength = trackLength
        self.events = events
        self.tracks = tracks
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    public static func ==(lhs: Measurement, rhs: Measurement) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}
