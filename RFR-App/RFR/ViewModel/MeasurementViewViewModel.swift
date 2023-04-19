/*
 * Copyright 2023 Cyface GmbH
 *
 * This file is part of the Read-for-Robots iOS App.
 *
 * The Read-for-Robots iOS App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Read-for-Robots iOS App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Read-for-Robots iOS App. If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation
import DataCapturing

/**
 The view model used by the page showing details about a single ``Measurement``.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - SeeAlso: ``MeasurementView``
 */
class MeasurementViewViewModel: ObservableObject {
    @Published var error: Error?
    @Published var isInitialized = false

    @Published var maxSpeed: String = ""
    @Published var meanSpeed: String = ""
    @Published var distance: String = ""
    @Published var duration: String = ""
    @Published var inclination: String = ""
    @Published var lowestPoint: String = ""
    @Published var highestPoint: String = ""
    @Published var avoidedEmissions: String = ""
    /// The title to display for the ``Measurement``
    @Published var title: String = ""
    /// The height profile data used to display a height graph.
    @Published var heightProfile: [Altitude] = [Altitude]()


    init(dataStoreStack: DataStoreStack, measurement: Measurement) {
        do {
            try dataStoreStack.wrapInContext { [weak self] context in
                guard let self = self else {
                    return
                }

                let request = MeasurementMO.fetchRequest()
                request.predicate = NSPredicate(format: "identifier == %d", measurement.id)
                let fetchResult = try request.execute()

                guard fetchResult.count == 1 else {
                    fatalError("Invalid database state. There are multiple measurements with the same identifier.")
                }

                guard let coreDataMeasurement = fetchResult.first else {
                    throw RFRError.unableToLoadMeasurement(measurement: measurement)
                }

                var maxSpeed = 0.0
                var sumSpeed = 0.0
                var locationCount = 0
                var summedDuration = TimeInterval()
                var lowestPoint = 0.0
                var highestPoint = 0.0
                for track in coreDataMeasurement.typedTracks() {
                    let locations = track.typedLocations()
                    guard let firstLocationTime = locations.first?.time else {
                        continue
                    }
                    guard let lastLocationTime = locations.last?.time else {
                        continue
                    }
                    summedDuration += lastLocationTime.timeIntervalSince(firstLocationTime)

                    locations.forEach { location in
                        maxSpeed = max(maxSpeed, location.speed)
                        sumSpeed += location.speed
                        locationCount += 1
                    }

                    track.typedAltitudes().enumerated().forEach { (index, altitude) in
                        heightProfile.append(Altitude(id: Int64(index), timestamp: altitude.time!, height: altitude.altitude))
                        lowestPoint = min(lowestPoint, altitude.altitude)
                        highestPoint = max(highestPoint, altitude.altitude)
                    }
                }
                let inclination = summedHeight(timelines: coreDataMeasurement.typedTracks())

                self.maxSpeed = "\(speedFormatter.string(from: maxSpeed as NSNumber)!) km/h"
                self.meanSpeed = "\(speedFormatter.string(from: (sumSpeed / Double(locationCount)) as NSNumber)!) km/h"
                self.distance = "\(distanceFormatter.string(from: coreDataMeasurement.trackLength as NSNumber)!) km"
                self.duration = timeFormatter.string(from: summedDuration)!
                self.inclination = "\(riseFormatter.string(from: inclination as NSNumber)!) m"
                self.lowestPoint = "\(riseFormatter.string(from: lowestPoint as NSNumber)!) m"
                self.highestPoint = "\(riseFormatter.string(from: highestPoint as NSNumber)!) m"
                self.avoidedEmissions = "\(emissionsFormatter.string(from: (coreDataMeasurement.trackLength * LiveViewModel.averageCarbonEmissionsPerMeter) as NSNumber)!) kg"

                isInitialized = true
            }
        } catch {
            self.error = error
        }
    }
}
