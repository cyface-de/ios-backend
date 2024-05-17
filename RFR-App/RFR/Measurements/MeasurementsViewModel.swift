/*
 * Copyright 2023-2024 Cyface GmbH
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
import DataCapturing
import Combine
import CoreLocation
import MapKit
import OSLog
import SwiftUI

/**
 The view model used by the ``MeasurementsView`` and ``StatisticsView``.

 Its core is a list of measurements that must be refreshed after each upload and when new measurements are created by the user.

 Since initialization can take a while, it provides a flag ``isLoading`` which should be checked before showing the actual UI.

 It also provides an optional ``error``, in case anything unforseen has happened.

 **ATTENTION:** It is important to call `setup after creation of an instance of this class, before actually using it. Otherwise `isLoading` will never become `false`.`

 - Author: Klemens Muthmann
 - Version: 1.0.1
 - Since: 3.1.2
 */
class MeasurementsViewModel: ObservableObject {
    // MARK: - Properties
    /// The measurements displayed by this view.
    @Published var measurements: [Measurement]
    /// A flag that is set to false as soon as all the measurements have been loaded. The UI should show a spinner until then.
    @Published var isLoading = true
    /// Contains the last error, that occurred or `nil` if everything is fine.
    @Published var error: Error? = nil
    let dataStoreStack: DataStoreStack
    // Statistics
    @Published var distance: String = ""
    @Published var duration: String = ""
    @Published var lowestPoint: String = ""
    @Published var highestPoint: String = ""
    @Published var incline: String = ""
    @Published var avoidedEmissions: String = ""
    @Published var maxAvoidedEmissions: String = ""
    @Published var meanAvoidedEmissions: String = ""

    // MARK: - Initializers
    /// Create a new object of this class.
    /// It gets data from the provided `dataStoreStack` and receives data upload information from the provided `uploadPublisher`.
    init(
        dataStoreStack: DataStoreStack
    ) {
        self.measurements = [Measurement]()
        self.dataStoreStack = dataStoreStack
    }

    /// Load the measurement data from the database asynchronously and update all the published properties.
    /// This finishes object initialization and causes the `isLoading` property to become `true`, which should trigger a redraw of the UI with the actual valid data.
    func setup() async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try dataStoreStack.wrapInContext { context in
                    let request = MeasurementMO.fetchRequest()
                    try request.execute().forEach { measurement in
                        measurements.append(load(measurement: measurement))
                    }

                    DispatchQueue.main.async { [weak self] in
                        self?.updateStatistics()
                        self?.isLoading = false
                        continuation.resume()
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Convert a database measurement into its representation as required by the user interface.
    private func load(measurement: MeasurementMO) -> Measurement {
        var maxSpeed = 0.0
        var sumSpeed = 0.0
        var locationCount = 0
        var summedDuration = TimeInterval()
        var lowestPoint = 0.0
        var highestPoint = 0.0
        var heightProfile = [Altitude]()
        let tracks = measurement.typedTracks()
        var coordinates = [CLLocationCoordinate2D]()
        var minimumLatitude = 90.0
        var minimumLongitude = 180.0
        var maximumLatitude = -90.0
        var maximumLongitude = -180.0
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

                coordinates.append(CLLocationCoordinate2D(latitude: location.lat, longitude: location.lon))

                minimumLatitude = min(minimumLatitude, location.lat)
                minimumLongitude = min(minimumLongitude, location.lon)
                maximumLatitude = max(maximumLatitude, location.lat)
                maximumLongitude = max(maximumLongitude, location.lon)
            }

            track.typedAltitudes().enumerated().forEach { (index, altitude) in
                heightProfile.append(Altitude(id: Int64(index), timestamp: altitude.time!, height: altitude.altitude))
                lowestPoint = min(lowestPoint, altitude.altitude)
                highestPoint = max(highestPoint, altitude.altitude)
            }
        }
        let inclination = Statistics.summedHeight(timelines: measurement.typedTracks())
        let distance = Statistics.coveredDistance(tracks: tracks)

        let latitudeDistance = maximumLatitude - minimumLatitude
        let longitudeDistance = maximumLongitude - minimumLongitude

        let southWestCorner = CLLocation(latitude: minimumLatitude, longitude: minimumLongitude)
        let northWestCorner = CLLocation(latitude: maximumLatitude, longitude: minimumLongitude)
        let northEastCorner = CLLocation(latitude: maximumLatitude, longitude: maximumLongitude)
        let center = CLLocationCoordinate2D(
            latitude: northWestCorner.coordinate.latitude - latitudeDistance/2,
            longitude: northWestCorner.coordinate.longitude + longitudeDistance/2
        )
        let northSouthReach = max(southWestCorner.distance(from: northWestCorner), 0.1)
        let eastWestReach = max(northWestCorner.distance(from: northEastCorner), 0.1)
        let synchronizationState = SynchronizationState.from(measurement: measurement)
        return Measurement(
            id: UInt64(measurement.identifier),
            startTime: measurement.time ?? Date(),
            synchronizationState: synchronizationState,
            _maxSpeed: maxSpeed,
            _meanSpeed: sumSpeed / Double(locationCount),
            _distance: distance,
            _duration: summedDuration,
            _inclination: inclination,
            _lowestPoint: lowestPoint,
            _highestPoint: highestPoint,
            _avoidedEmissions: Statistics.avoidedEmissions(distance),
            heightProfile: heightProfile,
            region: MKCoordinateRegion(
                center: center,
                latitudinalMeters: northSouthReach + northSouthReach * 0.15,
                longitudinalMeters: eastWestReach + eastWestReach * 0.15
            ),
            track: coordinates
        )
    }

    /// Causes a reload and redrawn each time measurement data changes.
    public func onMeasurementsChanged() {
        do {
            try dataStoreStack.wrapInContext { context in
                let measurementRequest = MeasurementMO.fetchRequest()
                let storedMeasurements = try measurementRequest.execute()
                os_log("Loaded changed measurements", log: OSLog.measurement, type: .debug)

                storedMeasurements.filter { storedMeasurement in
                    for measurement in measurements {
                        if measurement.id == storedMeasurement.identifier {
                            return false
                        }
                    }
                    return true
                }.forEach { filtered in
                    let measurement = self.load(measurement: filtered)
                    DispatchQueue.main.async { [weak self] in
                        if let self = self {
                            self.measurements.append(measurement)
                            updateStatistics()
                        }
                    }
                }
            }
        } catch {
            os_log("%@", log: OSLog.measurement, type: .error, error.localizedDescription)
            self.error = error
        }
    }

    /// Refresh the statistics values based on the current ``measurements`` array.
    private func updateStatistics() {
        let meanDistance = summedDistance() / Double(measurements.count)

        self.distance = "\(distanceFormatter.string(from: maxDistance() as NSNumber)!) km (\u{2205} \(distanceFormatter.string(from: (meanDistance.isNaN ? 0 : meanDistance) as NSNumber)!) km)"
        let totalDuration = totalDuration()
        let meanDuration = totalDuration / Double(measurements.count)

        self.duration = "\(timeFormatter.string(from: totalDuration)!) (\u{2205} \(timeFormatter.string(from: meanDuration.isNaN ? 0 : meanDuration)!))"

        self.lowestPoint = "\(riseFormatter.string(from: calculateLowestPoint() as NSNumber)!) m"
        self.highestPoint = "\(riseFormatter.string(from: calculateHighestPoint() as NSNumber)!) m"

        let meanIncline = summedIncline() / Double(measurements.count)

        self.incline = "max \(riseFormatter.string(from: maxIncline() as NSNumber)!) m (\u{2205} \(riseFormatter.string(from: meanIncline.isNaN ? 0 : meanIncline as NSNumber)!) m)"

        self.avoidedEmissions = "\(emissionsFormatter.string(from: sumOfAvoidedEmissions() as NSNumber)!) g"

        self.maxAvoidedEmissions = "\(emissionsFormatter.string(from: calculateMaxAvoidedEmissions() as NSNumber)!) g"

        let meanAvoidedEmissions = sumOfAvoidedEmissions() / Double(measurements.count)
        self.meanAvoidedEmissions = "\(emissionsFormatter.string(from: meanAvoidedEmissions.isNaN ? 0 : meanAvoidedEmissions as NSNumber)!) g"
    }

    /// Calculate the distance sum of all ``measurements`` in meters.
    private func summedDistance() -> Double {
        return measurements.map { $0._distance }.reduce(0.0) {
            $0 + $1
        }
    }

    /// Search for the length of the longest ``measurement`` in meters.
    private func maxDistance() -> Double {
        return measurements.map { $0._distance }.max() ?? 0.0
    }

    /// Calculate the total duration of all captured ``measurements``.
    private func totalDuration() -> TimeInterval {
        return measurements.map { $0._duration }.reduce(TimeInterval()) {
            $0 + $1
        }
    }

    /// Calculate the deepest depth reached with respect to the starting height in meters.
    private func calculateLowestPoint() -> Double {
        return measurements.map { $0._lowestPoint }.min() ?? 0.0
    }

    /// Calculate the highest height reached with respect to the starting height in meters.
    private func calculateHighestPoint() -> Double {
        return measurements.map { $0._highestPoint }.max() ?? 0.0
    }

    /// Calculate the sum of all positive inclinations from all captured ``measurements`` in meters.
    private func summedIncline() -> Double {
        return measurements.map { $0._inclination }.reduce(0.0) { $0 + $1 }
    }

    /// Search for the inclination of the measurement with the most inclination among all the captured ``measurements`` in meters.
    private func maxIncline() -> Double {
        return measurements.map { $0._inclination }.max() ?? 0.0
    }

    /// Calculate the sum of all the avoided emissions wth respect to car traffic for all captured ``measurements`` in gram.
    private func sumOfAvoidedEmissions() -> Double {
        return measurements.map { $0._avoidedEmissions }.reduce(0.0) { $0 + $1 }
    }

    /// Search for the avoided emissions of the captured measurement with the most avoided emissions in gram.
    private func calculateMaxAvoidedEmissions() -> Double {
        return measurements.map { $0._avoidedEmissions }.max() ?? 0.0
    }
}
