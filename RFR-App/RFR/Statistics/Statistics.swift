//
//  Statistics.swift
//  RFR
//
//  Created by Klemens Muthmann on 17.04.23.
//

import Foundation
import OSLog
import DataCapturing
import CoreLocation

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

func averageSpeed(timelines: [MeasurementTimeline]) -> Double {
    return averageSpeed(timelines: timelines.map { $0.measurements })
}

func averageSpeed(timelines: [[MeasurementPoint]]) -> Double {
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

func duration(timelines: [MeasurementTimeline]) -> Double {
    return duration(timelines: timelines.map { $0.measurements })
}

func duration(timelines: [[MeasurementPoint]]) -> Double {
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

protocol AltitudeTimeline {
    var sattelite: [SatteliteAltitude] { get }
    var barometric: [BarometricAltitude] { get }
}

protocol MeasurementTimeline {
    var measurements: [MeasurementPoint] { get }
}

protocol SatteliteAltitude {
    var value: Double { get }
    var accuracy: Double { get }
}

protocol MeasurementPoint {
    var speed: Double { get }
    var timestamp: Date? { get }
}

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

func loadAlleyCatData(fileName: String, ext: String) -> [AlleyCatMarker] {
    guard let filepath = Bundle.main.path(forResource: fileName, ofType: ext) else {
        return [AlleyCatMarker]()
    }

    var data = ""
    do {
        data = try String(contentsOfFile: filepath)
    } catch {
        print(error)
        return [AlleyCatMarker]()
    }

    var rows = data.components(separatedBy: "\n")
    rows.removeFirst()

    var markers = [AlleyCatMarker]()
    var isStart = true
    for row in rows {
        let columns = row.components(separatedBy: ",")
        guard let longitude = Double(columns[0]) else {
            continue
        }
        guard let latitude = Double(columns[1]) else {
            continue
        }
        let description = columns[2]

        let marker = AlleyCatMarker(
            location: CLLocationCoordinate2D(
                latitude: latitude,
                longitude: longitude
            ),
            description: description,
            markerType: isStart ? .start : .standard
        )
        markers.append(marker)
        isStart = false
    }

    return markers
}
