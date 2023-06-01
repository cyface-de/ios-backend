//
//  Statistics.swift
//  RFR
//
//  Created by Klemens Muthmann on 17.04.23.
//

import Foundation
import OSLog
import DataCapturing

/// The minimum number of meters before the ascend is increased, to filter sensor noise.
let ascendThresholdMeters = 2.0
/// The minimum accuracy in meters for GNSS altitudes to be used in ascend calculation.
let verticalAccuracyThresholdMeters = 12.0

/// Calculate the accumulated height value for this measurement.
func summedHeight(timelines: [AltitudeTimeline]) -> Double {
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
                } else if !(satteliteAltitude.accuracy > verticalAccuracyThresholdMeters) {

                    let currentAltitude = satteliteAltitude.value
                    let altitudeChange = currentAltitude - previousAltitude

                    if abs(altitudeChange) > ascendThresholdMeters {
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

/// The average carbon emissions per kilometer in gramms, based on data from Statista (https://de.statista.com/infografik/25742/durchschnittliche-co2-emission-von-pkw-in-deutschland-im-jahr-2020/)
let averageCarbonEmissionsPerMeter = 0.117

func avoidedEmissions(_ distanceInMeters: Double) -> Double {
    return distanceInMeters * averageCarbonEmissionsPerMeter
}

func coveredDistance(tracks: [TrackMO]) -> Double {
    var ret = 0.0
    tracks.forEach { track in
        var prevLocation: GeoLocationMO?
        track.typedLocations().forEach { location in
            ret += prevLocation?.distance(to: location) ?? 0.0
            prevLocation = location
        }
    }
    return ret
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
