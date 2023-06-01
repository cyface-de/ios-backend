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
                    /*let distance = measurement.trackLength
                    maxDistance = max(maxDistance, distance)
                    summedDistance += distance*/

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

                    /*let avoidedEmissions = measurement.trackLength * LiveViewModel.averageCarbonEmissionsPerMeter
                    maxAvoidedEmissions = max(maxAvoidedEmissions, avoidedEmissions)
                    sumOfAvoidedEmissions += avoidedEmissions*/

                    let height = summedHeight(timelines: measurement.typedTracks())
                    maxIncline = max(height, maxIncline)
                    sumIncline += height
                }
                var meanDistance = summedDistance / Double(measurements.count)
                var meanDuration = totalDuration / Double(measurements.count)
                var meanAvoidedEmissions = sumOfAvoidedEmissions / Double(measurements.count)
                var meanIncline = sumIncline / Double(measurements.count)

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

