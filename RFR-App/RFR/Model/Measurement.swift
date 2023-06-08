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
import Combine
import SwiftUI
import CoreLocation
import MapKit

/**
 A struct representing a measurement as required by the user interface of the application.`

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
struct Measurement: Identifiable {
    /// The identifier to use this object as part of a `List` or a `ForEach`. This may be the system wide unique measurement identifier, also used by the database.
    let id: UInt64
    /// The total distance travelled while measuring this.
    /// The time and date at which this measurement started.
    let startTime: Date
    /// The state of  synchronizting this measurement.
    let synchronizationState: SynchronizationState
    //@Published var error: Error?
    //@Published var isInitialized = false

    let _maxSpeed: Double
    var maxSpeed: String {
        "\(speedFormatter.string(from: _maxSpeed as NSNumber) ?? "0.0") km/h"
    }
    let _meanSpeed: Double
    var meanSpeed: String {
        "\(speedFormatter.string(from: _meanSpeed as NSNumber) ?? "0.0") km/h"
    }
    let _distance: Double
    var distance: String {
        return "\(distanceFormatter.string(from: _distance as NSNumber) ?? "0.0") km"
    }
    let _duration: TimeInterval
    var duration: String {
        timeFormatter.string(from: _duration) ?? "00:00:00"
    }
    let _inclination: Double
    var inclination: String {
        "\(riseFormatter.string(from: _inclination as NSNumber) ?? "0.0") m"
    }
    let _lowestPoint: Double
    var lowestPoint: String {
        "\(riseFormatter.string(from: _lowestPoint as NSNumber)!) m"
    }
    let _highestPoint: Double
    var highestPoint: String {
        "\(riseFormatter.string(from: _highestPoint as NSNumber)!) m"
    }
    let _avoidedEmissions: Double
    var avoidedEmissions: String {
        "\(emissionsFormatter.string(from: (RFR.avoidedEmissions(self._distance)) as NSNumber)!) kg"
    }
    /// The title to display for the ``Measurement``
    var title: String {
        "Messung \(id)"
    }
    /// The height profile data used to display a height graph.
    let heightProfile: [Altitude]
    //private let dataStoreStack: DataStoreStack
    /// The symbol showing the current synchronization status of the ``Measurement``.
    @ViewBuilder var synchedSymbol: some View {
        switch synchronizationState {
        case .synchronized:
            Image(systemName: "checkmark.icloud")
                .font(.subheadline)
        case .synchronizing:
            ProgressView()
        case .synchronizable:
            Image(systemName: "icloud.and.arrow.up")
                .font(.subheadline)
        }
    }
    var details: String {
        guard let formattedDistance = distanceFormatter.string(from: _distance as NSNumber) else {
            fatalError()
        }

        return "\(startTime.formatted()) (\(formattedDistance) km)"
    }
    let region: MKCoordinateRegion
    let track: [CLLocationCoordinate2D]

    func change(state: SynchronizationState) -> Measurement {
        return Measurement(
            id: self.id,
            startTime: self.startTime,
            synchronizationState: state,
            _maxSpeed: self._maxSpeed,
            _meanSpeed: self._meanSpeed,
            _distance: self._distance,
            _duration: self._duration,
            _inclination: self._inclination,
            _lowestPoint: self._lowestPoint,
            _highestPoint: self._highestPoint,
            _avoidedEmissions: self._avoidedEmissions,
            heightProfile: heightProfile,
            region: self.region,
            track: self.track)
    }

    /*init(identifier: UInt64, dataStoreStack: DataStoreStack) {
        self.id = identifier
        self.dataStoreStack = dataStoreStack
        do {
            try dataStoreStack.wrapInContext { [weak self] context in
                guard let self = self else {
                    return
                }

                let request = MeasurementMO.fetchRequest()
                request.predicate = NSPredicate(format: "identifier == %d", id)
                let fetchResult = try request.execute()

                guard fetchResult.count == 1 else {
                    fatalError("Invalid database state. There are multiple measurements with the same identifier.")
                }

                guard let coreDataMeasurement = fetchResult.first else {
                    throw RFRError.unableToLoadMeasurement(measurement: self)
                }

                var maxSpeed = 0.0
                var sumSpeed = 0.0
                var locationCount = 0
                var summedDuration = TimeInterval()
                var lowestPoint = 0.0
                var highestPoint = 0.0
                let tracks = coreDataMeasurement.typedTracks()
                for track in tracks {
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

                    track.typedAltitudes().enumerated().forEach { [weak self] (index, altitude) in
                        self?.heightProfile.append(Altitude(id: Int64(index), timestamp: altitude.time!, height: altitude.altitude))
                        lowestPoint = min(lowestPoint, altitude.altitude)
                        highestPoint = max(highestPoint, altitude.altitude)
                    }
                }
                let inclination = summedHeight(timelines: coreDataMeasurement.typedTracks())

                self.maxSpeed = "\(speedFormatter.string(from: maxSpeed as NSNumber)!) km/h"
                self.meanSpeed = "\(speedFormatter.string(from: (sumSpeed / Double(locationCount)) as NSNumber)!) km/h"
                // TODO: This iterates twice. Not very effective. Might become a problem with larger datasets.
                self._distance = coveredDistance(tracks: tracks)
                self.duration = timeFormatter.string(from: summedDuration)!
                self.inclination = "\(riseFormatter.string(from: inclination as NSNumber)!) m"
                self.lowestPoint = "\(riseFormatter.string(from: lowestPoint as NSNumber)!) m"
                self.highestPoint = "\(riseFormatter.string(from: highestPoint as NSNumber)!) m"
                self.avoidedEmissions = "\(emissionsFormatter.string(from: (RFR.avoidedEmissions(self._distance)) as NSNumber)!) kg"

                isInitialized = true
            }
        } catch {
            self.error = error
        }
    }*/
}

/**
 Provides an enum with the state of synchronization a measurement can be in.

 Each measurement start as synchronizable, switches to synchronizing as soon as the upload is running and ends as synchronized.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
enum SynchronizationState {
    case synchronizable
    case synchronizing
    case synchronized

    static func from(measurement: MeasurementMO) -> SynchronizationState {
        if measurement.synchronized {
            return .synchronized
        } else {
            return synchronizable
        }
    }
}
