/*
 * Copyright 2023 Cyface GmbH
 *
 * This file is part of the Ready for Robots App.
 *
 * The Ready for Robots App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Ready for Robots App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Ready for Robots App. If not, see <http://www.gnu.org/licenses/>.
 */
import Foundation
import OSLog
import DataCapturing
import CoreLocation

// TODO: This should probably become part of the MeasurementsViewModel
/**
 A collection of static utility methods for calculating statistics.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.2
 */
struct Statistics {
    /// The minimum number of meters before the ascend is increased, to filter sensor noise.
    static let ascendThresholdMeters = 2.0
    /// The minimum accuracy in meters for GNSS altitudes to be used in ascend calculation.
    static let verticalAccuracyThresholdMeters = 12.0

    /// Calculate the accumulated height value for this measurement.
    static func summedHeight(timelines: [AltitudeTimeline]) -> Double {
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

    /// Quelle: Verkehr in Zahlen 2018/2019: 47. Jahrgang Hamburg: DVV Media Group, 2018, 371 S. --> https://www.hvv-schulprojekte.de/unterrichtsmaterialien/kraftstoffverbrauch/#:~:text=Spezifischer%20Kraftstoffverbrauch%20der%20Pkw%20in%20Deutschland&text=Die%20Angaben%20f%C3%BCr%20jeden%20Autotyp,100%20km%20f%C3%BCr%20Benzin%2DPkw.
    /// Quelle 2: Deutscher Bundestag: https://www.bundestag.de/resource/blob/660794/dfdee26b00e44b018b04a187f0c6843e/WD-8-056-19-pdf-data.pdf
    /// Benzin: (2370 g/l * 7,7 l/100 km) / 100.000 = 0,18249 g/m
    /// Diesel: (2650 g/l * 6,8 l/100 km) / 100.000 = 0,1802 g/m
    /// Vertielung Diesel vs Bezin (Quelle: https://de.statista.com/statistik/daten/studie/994393/umfrage/verteilung-der-kraftstoffarten-zugelassener-pkw-in-deutschland/#:~:text=Am%201.,Prozent%20im%20Vergleich%20zum%20Vorjahr.)
    /// 63% Bezin vs 30% Diesel
    /// (0,18249 g/m * 63 + 0,1802 g/m * 30) / 93 = 0,180938709677419 g/m
    static let averageCarbonEmissionsInGrammsPerMeter = 0.180938709677419

    /// Calculate the avoided emissions for a covered distance, if that distance was covered by bike instead of by car.
    static func avoidedEmissions(_ distanceInMeters: Double) -> Double {
        return distanceInMeters * averageCarbonEmissionsInGrammsPerMeter
    }

    /// Calculate the distance covered by all the provided tracks in meters. Distance covered during a pause is left out.
    static func coveredDistance(tracks: [TrackMO]) -> Double {
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

    /// Calculate the average speed over an array of ``MeasurementTimeline`` instances.
    static func averageSpeed(timelines: [MeasurementTimeline]) -> Double {
        return averageSpeed(timelines: timelines.map { $0.measurements })
    }

    /// Calculate the average speed over an array of arrays of ``MeasurementPoint`` instances.
    /// This rather peculiar representation is created from the fact, that a measurement might consist of multiple tracks interrupted by pauses.
    static func averageSpeed(timelines: [[MeasurementPoint]]) -> Double {
        var sum = 0.0
        var counter = 0
        timelines.forEach { timeline in
            timeline.forEach { point in
                //if location.isValid {
                sum += point.speed
                counter += 1
                //}
            }
        }

        if counter==0 {
            return 0.0
        } else {
            return sum/Double(counter)
        }
    }

    /// Calculate the average speed over an array of ``MeasurementTimeline`` instances.
    static func duration(timelines: [MeasurementTimeline]) -> Double {
        return duration(timelines: timelines.map { $0.measurements })
    }

    /// Calculate the average speed over an array of arrays of ``MeasurementPoint`` instances.
    static func duration(timelines: [[MeasurementPoint]]) -> Double {
        return timelines.map { timeline in
            var totalTime = TimeInterval()
            if let firstTime = timeline.first?.timestamp,
               let lastTime = timeline.last?.timestamp {
                totalTime += lastTime.timeIntervalSince(firstTime)
            }
            return totalTime
        }
        .reduce(0.0) { accumulator, next in
            accumulator + next
        }
    }
}

/**
 A timeline of sattelite based and barometric altitude values.

 This protocol is required to make CoreData model objects compatible with the statistics.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.2
 */
protocol AltitudeTimeline {
    var sattelite: [SatteliteAltitude] { get }
    var barometric: [BarometricAltitude] { get }
}

/**
 A timeline of ``MeasurementPoint`` instances.

 This protocol is required to make CoreData model objects compatible with the statistics.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.2
 */
protocol MeasurementTimeline {
    var measurements: [MeasurementPoint] { get }
}

/**
 A timeline of ``SatteliteAltitude`` values.

 This protocol is required to make CoreData model objects compatible with the statistics.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.2
 */
protocol SatteliteAltitude {
    var value: Double { get }
    var accuracy: Double { get }
}

/**
 A single measurement point at a certain time of a certain speed.

 This protocol is required to make CoreData model objects compatible with the statistics.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.2
 */
protocol MeasurementPoint {
    var speed: Double { get }
    var timestamp: Date? { get }
}

/**
 A barometric altitude value as reported by the phones altitude API.

 This protocol is required to make CoreData model objects compatible with the statistics.

 - SeeAlso: The Apple documentation to get the exact meaning of this value. It is the raw value reported by the API.
 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.2
 */
protocol BarometricAltitude {
    var value: Double { get }
}

extension TrackMO: AltitudeTimeline, MeasurementTimeline {
    var barometric: [BarometricAltitude] {
        self.typedAltitudes()
    }

    var sattelite: [SatteliteAltitude] {
        self.typedLocations()
    }

    var measurements: [MeasurementPoint] {
        return typedLocations()
    }
}

extension GeoLocationMO: SatteliteAltitude, MeasurementPoint {
    var timestamp: Date? {
        self.time
    }

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

extension GeoLocation: MeasurementPoint {
    var timestamp: Date? {
        self.time
    }
}
