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
 * The Cyface SDK for iOS is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Cyface SDK for iOS. If not, see <http://www.gnu.org/licenses/>.
 */
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
                    let distance = measurement.trackLength()
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

                    let avoidedEmissions = distance * Statistics.averageCarbonEmissionsPerMeter
                    maxAvoidedEmissions = max(maxAvoidedEmissions, avoidedEmissions)
                    sumOfAvoidedEmissions += avoidedEmissions

                    let height = Statistics.summedHeight(timelines: measurement.typedTracks())
                    maxIncline = max(height, maxIncline)
                    sumIncline += height
                }
                let meanDistance = summedDistance / Double(measurements.count)
                let meanDuration = totalDuration / Double(measurements.count)
                let meanAvoidedEmissions = sumOfAvoidedEmissions / Double(measurements.count)
                let meanIncline = sumIncline / Double(measurements.count)

                self.maxDistance = "\(distanceFormatter.string(from: maxDistance as NSNumber)!) km"
                self.meansDistance = "\(distanceFormatter.string(from: (meanDistance.isNaN ? 0 : meanDistance) as NSNumber)!) km"
                self.summedDuration = timeFormatter.string(from: totalDuration) ?? ""
                self.meanDuration = timeFormatter.string(from: meanDuration.isNaN ? 0 : meanDuration) ?? ""
                self.lowestPoint = "\(riseFormatter.string(from: lowestPoint as NSNumber)!) m"
                self.highestPoint = "\(riseFormatter.string(from: hightestPoint as NSNumber)!) m"
                self.maxIncline = "\(riseFormatter.string(from: maxIncline as NSNumber)!) m"
                self.meanIncline = "\(riseFormatter.string(from: meanIncline.isNaN ? 0 : meanIncline as NSNumber)!) m"
                self.avoidedEmissions = "\(emissionsFormatter.string(from: sumOfAvoidedEmissions as NSNumber)!) kg"
                self.maxAvoidedEmissions = "\(emissionsFormatter.string(from: maxAvoidedEmissions as NSNumber)!) kg"
                self.meanAvoidedEmissions = "\(emissionsFormatter.string(from: meanAvoidedEmissions.isNaN ? 0 : meanAvoidedEmissions as NSNumber)!) kg"
                isInitialized = true
            }
        } catch {
            self.error = error
        }
    }
}

