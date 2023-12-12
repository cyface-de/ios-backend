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
class Measurement: Identifiable, ObservableObject {
    /// The identifier to use this object as part of a `List` or a `ForEach`. This may be the system wide unique measurement identifier, also used by the database.
    let id: UInt64
    /// The total distance travelled while measuring this.
    /// The time and date at which this measurement started.
    let startTime: Date
    /// The state of  synchronizting this measurement.
    @Published var synchronizationState: SynchronizationState

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
        "\(emissionsFormatter.string(from: (Statistics.avoidedEmissions(self._distance)) as NSNumber)!) kg"
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
        case .unsynchronizable:
            Image(systemName: "xmark.icloud")
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
        self._distance = _distance
        self._duration = _duration
        self._inclination = _inclination
        self._lowestPoint = _lowestPoint
        self._highestPoint = _highestPoint
        self._avoidedEmissions = _avoidedEmissions
        self.heightProfile = heightProfile
        self.region = region
        self.track = track
    }

    /*func change(state: SynchronizationState) -> Measurement {
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
            track: self.track
        )
    }*/
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
 - Version: 1.0.0
 */
enum SynchronizationState {
    case synchronizable
    case synchronizing
    case synchronized
    case unsynchronizable

    static func from(measurement: MeasurementMO) -> SynchronizationState {
        if measurement.synchronized {
            return .synchronized
        } else if measurement.synchronizable {
            return .synchronizable
        } else {
            return .unsynchronizable
        }
    }
}
