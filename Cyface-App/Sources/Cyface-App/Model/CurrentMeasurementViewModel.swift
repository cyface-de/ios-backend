/*
 * Copyright 2022 Cyface GmbH
 *
 * This file is part of the Cyface SDK for iOS.
 *
 * The Cyface SDK for iOS is free software: you can redistribute it and/or modify
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
import UIKit

/**
 The view model for displaying detail information about the currently captured measurement.

 The measurement is loaded from the Cyface backend and used to refresh the attributes necessary to show all the relevant information.
 All the attributes are formatted properly.

 - author: Klemens Muthmann
 - version: 1.0.0
 - since: 4.0.0
 */
class CurrentMeasurementViewModel: ObservableObject {
    /// The GPS status image presented to the user. This changes based on whether the App has a GPS fix or not.
    @Published var hasFix: UIImage
    /// The currently driven distance under the current measurement.
    @Published var distance: String
    /// The current speed as reported by the Cyface data capturing service.
    @Published var speed: String
    /// The duration of the measurement.
    @Published var duration: String
    /// The geographical latitude in degrees as a decimal number (not sexagesimal).
    @Published var latitude: String
    /// The geographical longitude in degress as a decimal number (not sexagesimal).
    @Published var longitude: String
    /// A flag that is `true` if there was an error, or `false` otherwise.
    @Published var hasError: Bool = false
    /// The error message to show, if any.
    @Published var errorMessage: String?
    /// The CoreData stack used to access the database and load information about the current measurement.
    private let coreDateStack: CoreDataManager
    /// The device wide unique identifier of the currently captured measurement.
    private let measurementIdentifier: Int64?

    /// Initialize this view model with all zero values and an initialized ``ApplicationState``.
    init(appState: ApplicationState, distance: String = "0 m", speed: String = "0 km/s", duration: String = "0 s", latitude: String = "0", longitude: String = "0") {
        self.hasFix = UIImage(named: "gps-not-available")!
        self.distance = distance
        self.speed = speed
        self.duration = duration
        self.latitude = latitude
        self.longitude = longitude
        self.coreDateStack = appState.dcs.coreDataStack
        self.measurementIdentifier = appState.dcs.currentMeasurement
        appState.dcs.handler.append(self.handle)
    }

}

extension CurrentMeasurementViewModel: CyfaceEventHandler {

    /// Formatter used to display the duration of the current measurement.
    private var timeFormatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()

        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter
    }

    /// The handler for Cyface `DataCapturingEvent` instances.
    ///
    /// This updates the current measurement view on each new geographical location.
    /// It also refreshes the geographical location fix display.
    func handle(event: DataCapturingEvent, status: Status) {
        switch status {
        case .success:
            switch event {
            case .geoLocationFixAcquired:
                if let hasFix = UIImage(named: "gps-available") {
                    DispatchQueue.main.async {
                        self.hasFix = hasFix
                    }
                }
            case .geoLocationFixLost:
                if let hasFix = UIImage(named: "gps-not-available") {
                    DispatchQueue.main.async {
                        self.hasFix = hasFix
                    }
                }
            case .geoLocationAcquired(position: let location):
                let persistenceLayer = PersistenceLayer(onManager: coreDateStack)
                do {
                    if let measurementIdentifier = measurementIdentifier {
                        let measurement = try persistenceLayer.load(measurementIdentifiedBy: measurementIdentifier)
                        let distanceInMeters = measurement.trackLength

                        if let formattedDuration = timeFormatter.string(from: abs(location.timestamp.timeIntervalSince(Date(timeIntervalSince1970: Double(measurement.timestamp) / 1_000.0)))) {
                            DispatchQueue.main.async {
                                self.duration = formattedDuration
                            }
                        }

                        DispatchQueue.main.async {
                            self.speed = String(format: "%.2f km/s", location.speed / 3.6)
                            self.latitude = String(format: "%.2f", location.latitude)
                            self.longitude = String(format: "%.2f", location.longitude)

                            self.distance = distanceInMeters < 1_000 ? String(format: "%.2f m", distanceInMeters) : String(format: "%.2f km", distanceInMeters / 1_000)
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.hasError = true
                        self.errorMessage = error.localizedDescription
                    }
                }
            default:
                break
            }
        default:
            break
        }
    }

}
