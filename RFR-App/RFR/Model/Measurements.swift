//
//  Measurements.swift
//  RFR
//
//  Created by Klemens Muthmann on 13.04.23.
//

import Foundation
import DataCapturing
import OSLog

/**
 Provides statistical information about all the measurements captured on this device.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
class Measurements: ObservableObject {
    var maxDistance: String = ""
    var meansDistance: String = ""
    var summedDuration: String = ""
    var meanDuration: String = ""
    var lowestPoint: String = ""
    var highestPoint: String = ""
    var maxIncline: String = ""
    var meanIncline: String = ""
    var avoidedEmissions: String = ""
    var maxAvoidedEmissions: String = ""
    var meanAvoidedEmissions: String = ""
    @Published var isInitialized = false
    @Published var error: Error?


    init(coreDataStack: DataStoreStack) {
        do {
            try coreDataStack.wrapInContext { context in
                let measurementsRequest = MeasurementMO.fetchRequest()
                let measurements = try measurementsRequest.execute()
                var maxDistance = 0.0
                var summedDistance = 0.0
                var totalDuration = TimeInterval()
                var lowestPoint = 0.0
                var hightestPoint = 0.0
                var maxIncline = 0.0
                var sumIncline = 0.0
                var sumOfAvoidedEmissions = 0.0
                var maxAvoidedEmissions = 0.0
                measurements.forEach { measurement in
                    let distance = measurement.trackLength
                    maxDistance = max(maxDistance, distance)
                    summedDistance += distance

                    var measurementDuration = TimeInterval()
                    measurement.typedTracks().forEach { track in
                        if let firstLocationTime = track.typedLocations().first?.time, let lastLocationTime = track.typedLocations().last?.time {
                            measurementDuration += lastLocationTime.timeIntervalSince(firstLocationTime)
                        }
                        track.typedAltitudes().forEach { altitude in
                            lowestPoint = min(lowestPoint, altitude.altitude)
                            hightestPoint = max(hightestPoint, altitude.altitude)
                        }
                    }
                    totalDuration += measurementDuration

                    let avoidedEmissions = measurement.trackLength * LiveViewModel.averageCarbonEmissionsPerMeter
                    maxAvoidedEmissions = max(maxAvoidedEmissions, avoidedEmissions)
                    sumOfAvoidedEmissions += avoidedEmissions

                    let height = summedHeight(timelines: measurement.typedTracks())
                    maxIncline = max(height, maxIncline)
                    sumIncline += height
                }
                var meanDistance = summedDistance / Double(measurements.count)
                var meanDuration = totalDuration / Double(measurements.count)
                var meanAvoidedEmissions = sumOfAvoidedEmissions / Double(measurements.count)
                var meanIncline = sumIncline / Double(measurements.count)

                self.maxDistance = "\(distanceFormatter.string(from: maxDistance as NSNumber)!) km"
                self.meansDistance = "\(distanceFormatter.string(from: meanDistance as NSNumber)!) km"
                self.summedDuration = timeFormatter.string(from: totalDuration)!
                self.meanDuration = timeFormatter.string(from: meanDuration)!
                self.lowestPoint = "\(riseFormatter.string(from: lowestPoint as NSNumber)!) m"
                self.highestPoint = "\(riseFormatter.string(from: hightestPoint as NSNumber)!) m"
                self.maxIncline = "\(riseFormatter.string(from: maxIncline as NSNumber)!) m"
                self.meanIncline = "\(riseFormatter.string(from: meanIncline as NSNumber)!) m"
                self.avoidedEmissions = "\(emissionsFormatter.string(from: sumOfAvoidedEmissions as NSNumber)!) kg"
                self.maxAvoidedEmissions = "\(emissionsFormatter.string(from: maxAvoidedEmissions as NSNumber)!) kg"
                self.meanAvoidedEmissions = "\(emissionsFormatter.string(from: meanAvoidedEmissions as NSNumber)!) kg"
                isInitialized = true
            }
        } catch {
            self.error = error
        }
    }

    /// Calculate the accumulated height value for this measurement.
    private func summedHeight(timelines: [AltitudeTimeline]) -> Double {
        var sum = 0.0
        timelines.forEach { timeline in

            if timeline.barometric.isEmpty {
                os_log("Using location values to calculate accumulated height.", log: OSLog.measurement, type: .debug)
                var previousAltitude = 0.0
                var isFirst = true
                timeline.sattelite.forEach { satteliteAltitude in
                    if isFirst {
                        previousAltitude = satteliteAltitude.value
                        isFirst = false
                    } else if !(satteliteAltitude.accuracy > DataCapturing.Measurement.verticalAccuracyThresholdMeters) {

                        let currentAltitude = satteliteAltitude.value
                        let altitudeChange = currentAltitude - previousAltitude

                        if abs(altitudeChange) > DataCapturing.Measurement.ascendThresholdMeters {
                            if altitudeChange > 0.0 {
                                sum += altitudeChange
                            }
                            previousAltitude = satteliteAltitude.value
                        }
                    }
                }
            } else {
                os_log("Using altimeter values to calculate accumulated height.", log: OSLog.measurement, type: .debug)
                var previousAltitude: Double? = nil
                for altitude in timeline.barometric {
                    if let previousAltitude = previousAltitude {
                        let relativeAltitudeChange = altitude.value - previousAltitude
                        if relativeAltitudeChange > 0.1 {
                            sum += relativeAltitudeChange
                        }
                    }
                    previousAltitude = altitude.value
                }
            }
        }
        return sum
    }
}

protocol AltitudeTimeline {
    var sattelite: [SatteliteAltitude] { get }
    var barometric: [BarometricAltitude] { get }
}

protocol SatteliteAltitude {
    var value: Double { get }
    var accuracy: Double { get }
}

protocol BarometricAltitude {
    var value: Double { get }
}

extension TrackMO: AltitudeTimeline {
    var barometric: [BarometricAltitude] {
        self.typedAltitudes()
    }

    var sattelite: [SatteliteAltitude] {
        self.typedLocations()
    }
}

extension GeoLocationMO: SatteliteAltitude {
    var value: Double {
        self.altitude
    }

    var accuracy: Double {
        self.verticalAccuracy
    }
}

extension AltitudeMO: BarometricAltitude {
    var value: Double {
        self.altitude
    }
}
