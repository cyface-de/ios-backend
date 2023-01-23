/*
 * Copyright 2023 Cyface GmbH
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
import CoreMotion
import CoreData
import OSLog

/**
 Represents all the data only required by this branch of the SDK. This currently encompasses altitude data and related structures.

 The altitude can be provided either by an altimeter or by the sattelite based geo location sensor (GPS, etc.).

 - Author: Klemens Muthmann
 */
public class V11Database {
    // MARK: - Properties
    /// A *CoreData* Stack used to
    private let coreDataStack: CoreDataManager
    /// The minimum number of meters before the ascend is increased, to filter sensor noise.
    private static let ascendThresholdMeters = 2.0
    /// Only altimeter changes above this value are considered to be valid height changes. Everything below is considered to be noise.
    private static let altimeterNoiseThreshold = 0.1
    /// The minimum accuracy in meters for GNSS altitudes to be used in ascend calculation.
    private static let verticalAccuracyThresholdMeters = 12.0
    /// A queue to synchronize write operations to this database.
    private static let writeQueue = DispatchQueue(label: "v11-database-write-queue")
    /// The logger used by this object.
    private let log = OSLog(subsystem: "StatisticsApp", category: "de.cyface")

    // MARK: - Initializers

    /// Create a new instance of this data access object using the provided *CoreData* stack.
    public init(coreDataStack: CoreDataManager) {
        self.coreDataStack = coreDataStack
    }

    // MARK: - Storing Raw Data

    /// Store Altimeter altitude values to the provided measurement.
    func store(altitudes: [Altitude], to measurement: Measurement) throws {
        try coreDataStack.wrapInContext { context in
            let v11Measurement = try loadV11Measurement(for: measurement, from: context)

            let v11Track = v11Measurement.lastTrack()

            altitudes.forEach { altitude in
                let altitudeMO = AltitudeMO(context: context)
                altitudeMO.altitude = altitude.relativeAltitude
                altitudeMO.timestamp = altitude.timestamp
                v11Track.addToAltitudes(altitudeMO)
            }
            try context.save()
        }
    }

    /// Store the provided locations, containing altitude information, with the `Measurement`.
    func store(locations: [LocationCacheEntry], to measurement: Measurement) throws {
        try coreDataStack.wrapInContext { context in
            let v11Measurement = try loadV11Measurement(for: measurement, from: context)

            let v11Track = v11Measurement.lastTrack()

            locations.forEach { location in
                let locationMO = GeoLocationWithAltitudeMO(context: context)
                locationMO.altitude = location.altitude
                locationMO.verticalAccuracy = location.verticalAccuracy
                locationMO.speed = location.speed
                locationMO.timestamp = Int64(location.timestamp.timeIntervalSince1970 * 1000.0)
                locationMO.accuracy = location.accuracy
                locationMO.isPartOfCleanedTrack = location.isValid
                locationMO.lat = location.latitude
                locationMO.lon = location.longitude
                v11Track.addToLocations(locationMO)
            }

            try context.save()
        }
    }

    /// Load a `measurement` from the data storage.
    private func loadV11Measurement(for measurement: Measurement, from context: NSManagedObjectContext) throws -> MeasurementV11 {
        try V11Database.writeQueue.sync {
            let fetchRequest = MeasurementV11.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "identifier = %i", measurement.identifier)
            let dbMeasurements = try context.fetch(fetchRequest)
            guard dbMeasurements.count <= 1 else {
                throw PersistenceError.inconsistentState
            }

            if dbMeasurements.isEmpty {
                let newV11Measurement = MeasurementV11(context: context)
                newV11Measurement.identifier = measurement.identifier
                newV11Measurement.addToTracks(TrackV11(context: context))
                return newV11Measurement
            } else {
                while dbMeasurements[0].typedTracks().count < measurement.tracks.count {
                    dbMeasurements[0].addToTracks(TrackV11(context: context))
                }
                return dbMeasurements[0]
            }
        }
    }

    // MARK: - Reading Calculated Results

    /// Calculate the accumulated height value for the provided `Measurement`.
    public func summedHeight(measurement: Measurement) throws -> Double {
        try coreDataStack.wrapInContextReturn { context in
            let measurementV11 = try MeasurementV11.load(measurement: measurement, context: context)

            var sum = 0.0
            measurementV11.typedTracks().forEach { track in
                let altimeterAltitudes = track.typedAltitudes()

                if altimeterAltitudes.isEmpty {
                    os_log("Using location values to calculate accumulated height.", log: log, type: .debug)
                    let locationAltitudes = track.typedLocations()
                    var previousAltitude = 0.0
                    var isFirst = true
                    locationAltitudes.forEach { location in
                        if isFirst {
                            previousAltitude = location.altitude
                            isFirst = false
                        } else if !(location.verticalAccuracy > V11Database.verticalAccuracyThresholdMeters) {

                            let currentAltitude = location.altitude
                            let altitudeChange = currentAltitude - previousAltitude

                            if abs(altitudeChange) > V11Database.ascendThresholdMeters {
                                if altitudeChange > 0.0 {
                                    sum += altitudeChange
                                }
                                previousAltitude = location.altitude
                            }
                        }
                    }

                } else {
                    // Calculation using a low pass filter to remove noise
                    os_log("Using altimeter values to calculate accumulated height.", log: log, type: .debug)
                    var value = 0.0
                    let filterFactor = 0.1
                    altimeterAltitudes.forEach { altitude in
                        let relativeAltitudeChange = altitude.altitude
                        if relativeAltitudeChange > 0.0 {
                            value = filterFactor * value + (1.0 - filterFactor) * relativeAltitudeChange
                            sum += value
                        }
                    }

                }
            }
            return sum
        }
    }
}
