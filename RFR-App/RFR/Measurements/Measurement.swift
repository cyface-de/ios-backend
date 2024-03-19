/*
 * Copyright 2023 Cyface GmbH
 *
 * This file is part of the Ready for Robots iOS App.
 *
 * The Ready for Robots iOS App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Ready for Robots iOS App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Ready for Robots iOS App. If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation
import DataCapturing
import Combine
import SwiftUI
import CoreLocation
import MapKit

/**
 A class for objects representing a measurement as required by the user interface of the application.`

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since 3.1.1
 */
class Measurement: Identifiable, ObservableObject {
    // MARK: - Properties
    /// The identifier to use this object as part of a `List` or a `ForEach`. This may be the system wide unique measurement identifier, also used by the database.
    let id: UInt64
    /// The total distance travelled while measuring this.
    /// The time and date at which this measurement started.
    let startTime: Date
    /// The state of  synchronizting this measurement.
    @Published var synchronizationState: SynchronizationState

    /// Internal storage for the maximum speed achieved during the measurement in kilometers per hour.
    let _maxSpeed: Double
    /// Internal storage for the mean speed achieved during the measurement in kilometers per hour.
    let _meanSpeed: Double
    /// UI representation of the maximum speed achieved during the measurement in kilometers per hour.
    let speed: String

    /// Internal storage for the distance travelled during this measurement in kilometers.
    let _distance: Double
    /// UI representation of the distance travelled during this measurement in kilometers.
    let distance: String

    /// Internal storage for the duration of this measurement.
    var _duration: TimeInterval
    /// UI representation of the duration of this measurement.
    var duration: String

    /// Internal storage for the inclination achieved during this measurement in meters.
    var _inclination: Double
    /// UI representation of the inclincation achieved during this measurement in meters.
    var inclination: String

    /// Internal storage for the lowest point achieved during this measurement with respect to the starting point in meters..
    var _lowestPoint: Double
    /// UI representation of the lowest point achieved during this measurement with repsect to the starting point in meters.
    var lowestPoint: String

    /// Internal storage for the highest point achieved during this measurement with respect to the starting point in meters.
    var _highestPoint: Double
    /// UI representation of the highest point achieved during this measurement with respect to the starting point in meters.
    var highestPoint: String

    /// Internal storage for the amount of avoided emissions in kilograms CO2 during this measurement.
    var _avoidedEmissions: Double
    /// UI representation for the avoided emissions in kilograms CO2 during this measurement.
    var avoidedEmissions: String
    /// The title to display for the ``Measurement``
    var title: String {
        "Messung \(id)"
    }
    /// The height profile data used to display a height graph.
    let heightProfile: [Altitude]

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
        case .unsynchronizable:
            Image(systemName: "xmark.icloud")
                .font(.subheadline)
        }
    }

    /// Summary shown for this measurement in the view showing all the measurements.
    var details: String {
        guard let formattedDistance = distanceFormatter.string(from: _distance as NSNumber) else {
            fatalError()
        }

        return "\(startTime.formatted()) (\(formattedDistance) km)"
    }
    /// A *MapKit* region for the bounding box of this measurement, to show it inside a MapView on screen.
    let region: MKCoordinateRegion
    /// The locations for this measurement as a *CoreLocation* track, to show it in a MapView.
    let track: [CLLocationCoordinate2D]

    // MARK: - Initializers
    /**
     Create a new object of this class, with all the properties initialized with the provided values.
     */
    init(
        id: UInt64,
        startTime: Date,
        synchronizationState: SynchronizationState,
        _maxSpeed: Double,
        _meanSpeed: Double,
        _distance: Double,
        _duration: Double,
        _inclination: Double,
        _lowestPoint: Double,
        _highestPoint: Double,
        _avoidedEmissions: Double,
        heightProfile: [Altitude],
        region: MKCoordinateRegion,
        track: [CLLocationCoordinate2D]
    ) {
        self.id = id
        self.startTime = startTime
        self.synchronizationState = synchronizationState
        self._maxSpeed = _maxSpeed
        self._meanSpeed = _meanSpeed
        self.speed = Measurement.formatSpeed(_maxSpeed, _meanSpeed)
        self._distance = _distance
        self.distance = "\(distanceFormatter.string(from: _distance as NSNumber) ?? "0.0") km"
        self._duration = _duration
        self.duration = timeFormatter.string(from: _duration) ?? "00:00:00"
        self._inclination = _inclination
        self.inclination = "\(riseFormatter.string(from: _inclination as NSNumber) ?? "0.0") m"
        self._lowestPoint = _lowestPoint
        self.lowestPoint = "\(riseFormatter.string(from: _lowestPoint as NSNumber) ?? "0.0") m"
        self._highestPoint = _highestPoint
        self.highestPoint = "\(riseFormatter.string(from: _highestPoint as NSNumber) ?? "0.0") m"
        self._avoidedEmissions = _avoidedEmissions
        self.avoidedEmissions = "\(emissionsFormatter.string(from: (Statistics.avoidedEmissions(self._distance)) as NSNumber) ?? "0.0") g"
        self.heightProfile = heightProfile
        self.region = region
        self.track = track
    }

    // MARK: - Static Methods
    /// Format the speed property for display on the UI.
    private static func formatSpeed(_ max: Double, _ mean: Double) -> String {
        let maxSpeed = if max >= 0.0 { max } else { 0.0 }
        let meanSpeed = if mean >= 0.0 { mean } else { 0.0 }
        let formattedMaxSpeed = if let formattedSpeed = speedFormatter.string(from: maxSpeed as NSNumber) {
            formattedSpeed
        } else {
            speedFormatter.string(from: NSNumber(floatLiteral: 0.0)) ?? "0.0"
        }
        let formattedMeanSpeed = if let formattedSpeed = speedFormatter.string(from: meanSpeed as NSNumber) {
            formattedSpeed
        } else {
            speedFormatter.string(from: NSNumber(floatLiteral: 0.0)) ?? "0.0"
        }

        return "\(formattedMaxSpeed) km/h (\u{2205} \(formattedMeanSpeed) km/h)"
    }
}

extension Measurement: Hashable {
    static func == (lhs: Measurement, rhs: Measurement) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/**
 Provides an enum with the state of synchronization a measurement can be in.

 Each measurement start as synchronizable, switches to synchronizing as soon as the upload is running and ends as synchronized.

 - Author: Klemens Muthmann
 - Version: 1.0.1
 - Since: 3.1.1
 */
enum SynchronizationState {
    /// Identifies a measurement that is ready to be synchronized. This mostly means it was finished by pressing stop.
    case synchronizable
    /// Identifies a measurement that is currently in the process of being uploaded. This means the UI should generally show some kind of activity indicator.
    case synchronizing
    /// Identifies a measurement that has been successfully synchronized. The UI should show some success indicator in this case.
    case synchronized
    /// Identifies a measurement that is not synchronizable. Maybe there was an error or the data collector rejected it for some reason. The UI should show an error indicator.
    case unsynchronizable

    /// Convert a database `MeasurementMO` to its `SynchronizationState`
    static func from(measurement: MeasurementMO) -> SynchronizationState {
        let request = UploadSession.fetchRequest()
        request.predicate = NSPredicate(format: "measurement=%@", measurement)
        request.fetchLimit = 1
        do {
            let sessions = try request.execute()
            if !sessions.isEmpty {
                return .synchronizing
            } else if measurement.synchronized {
                return .synchronized
            } else if measurement.synchronizable {
                return .synchronizable
            } else {
                return .unsynchronizable
            }
        } catch {
            return .unsynchronizable
        }
    }
}
