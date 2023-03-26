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
            try V11Database.writeQueue.sync {
                do {
                    let v11Measurement = try loadV11Measurement(for: measurement, from: context)

                    let v11Track = v11Measurement.lastTrack()

                    altitudes.forEach { altitude in
                        let altitudeMO = AltitudeMO(context: context)
                        altitudeMO.altitude = altitude.relativeAltitude
                        altitudeMO.timestamp = altitude.timestamp
                        v11Track.addToAltitudes(altitudeMO)
                    }
                } catch {
                    throw PersistenceError.unableToLoadV11Altitudes(measurement, error)
                }

                do {
                    try context.save()
                } catch {
                    throw PersistenceError.unableToStoreV11Altitudes(measurement, error)
                }
            }
        }
    }

    /// Store the provided locations, containing altitude information, with the `Measurement`.
    func store(locations: [LocationCacheEntry], to measurement: Measurement) throws {
        try coreDataStack.wrapInContext { context in
            try V11Database.writeQueue.sync {
                do {
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
                } catch {
                    throw PersistenceError.unableToLoadV11Locations(measurement, error)
                }
                do {
                    try context.save()
                } catch {
                    throw PersistenceError.unableToStoreV11Locations(measurement, error)
                }
            }
        }
    }

    /// Load a `measurement` from the data storage.
    private func loadV11Measurement(for measurement: Measurement, from context: NSManagedObjectContext) throws -> MeasurementV11 {
        let fetchRequest = MeasurementV11.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier = %i", measurement.identifier)
        do {
            let dbMeasurements = try context.fetch(fetchRequest)
            guard dbMeasurements.count <= 1 else {
                throw PersistenceError.measurementNotLoadable(measurement.identifier)
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
        } catch {
            throw PersistenceError.measurementV11NotLoadable(measurement, error)
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
                    os_log("Using altimeter values to calculate accumulated height.", log: log, type: .debug)
                    // Calculation using a low pass filter to remove noise
                    //let filter = TriangularFilter()
                    //let smoothedSignal = filter.filter(signal: relativeAltitudeChanges(altitudes: altimeterAltitudes), windowSize: 11)
                    //sum = addPositiveChanges(signal: smoothedSignal)
                    var previousAltitude: Double? = nil
                    for altitude in altimeterAltitudes {
                        if let previousAltitude = previousAltitude {
                            let relativeAltitudeChange = altitude.altitude - previousAltitude
                            if relativeAltitudeChange > 0.1 {
                                sum += relativeAltitudeChange
                            }
                        }
                        previousAltitude = altitude.altitude
                    }
                }
            }
            return sum
        }
    }

    private func relativeAltitudeChanges(altitudes: [AltitudeMO]) -> [Double] {
        var ret = [Double]()

        var previousAltitude: Double?
        for altitude in altitudes {
            if let previousAltitude = previousAltitude {
                ret.append(altitude.altitude - previousAltitude)
            }
            previousAltitude = altitude.altitude
        }

        return ret
    }

    private func addPositiveChanges(signal: [Double]) -> Double {
        var sum = 0.0
        for value in signal {
            if value > 0.2, value < 3.0 {
                sum += value
            }
        }

        return sum
    }
}

// https://maker.pro/arduino/tutorial/how-to-clean-up-noisy-sensor-data-with-a-moving-average-filter
struct SmoothingAlgorithm {
    var index = 0
    var value = 0.0
    var sum = 0.0
    var readings: [Double]
    var averaged = 0.0

    func smooth(value: Double) -> SmoothingAlgorithm {
        let windowSize = readings.count
        var readings = readings.map { $0 }
        var sum = sum - readings[index]         // Remove the oldest entry from the sum
        readings[index] = value                 // Add the newest reading to the window
        sum = sum + value                       // Add the newest reading to the sum
        let index = (index+1) % windowSize      // Increment the index, and wrap to 0 if it exceeds the window size

        let averaged = sum / Double(windowSize) // Divide the sum of the window by the window size for the result

        return SmoothingAlgorithm(index: index, value: value, sum: sum, readings: readings, averaged: averaged)
    }
}

struct NoiseFilter {
    var filteredValue = 0.0
    let kFilteringFactor: Double

    func smooth(value: Double) -> NoiseFilter {
        let filteredValue = (value * kFilteringFactor) + (filteredValue * (1.0 - kFilteringFactor))
        return NoiseFilter(filteredValue: filteredValue, kFilteringFactor: kFilteringFactor)
    }
}

protocol SignalFilter {
    func filter(signal: [Double], windowSize: Int) -> [Double]
}

class TriangularFilter: SignalFilter {
    func filter(signal: [Double], windowSize: Int) -> [Double] {
        guard windowSize%2 != 0 else {
            fatalError("Triangular Filtering is only possible with odd sized windows! Window size \(windowSize) is not valid!")
        }
        var ret = [Double]()
        if signal.count-windowSize > 0 {
            for index in 0..<signal.count-windowSize {
                let fromIndex = index
                let toIndex = index+windowSize-1
                if toIndex < signal.count {
                    let currentWindow = signal[fromIndex...toIndex]
                    let smoothedValue = triangularFilter(window: Array(currentWindow))
                    ret.append(smoothedValue)
                }
            }
        }
        return ret
    }

    private func triangularFilter(window: [Double]) -> Double {
        var smoothedValue = 0.0
        var denominator = 0.0
        for index in 0..<window.count {
            let weight = index-(window.count/2)>0 ? Double(window.count-index) : Double(index+1)
            denominator += weight
            smoothedValue += weight * window[index]
        }
        return smoothedValue/denominator
    }
}
