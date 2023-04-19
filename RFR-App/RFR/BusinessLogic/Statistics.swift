//
//  Statistics.swift
//  RFR
//
//  Created by Klemens Muthmann on 17.04.23.
//

import Foundation
import OSLog
import DataCapturing

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
