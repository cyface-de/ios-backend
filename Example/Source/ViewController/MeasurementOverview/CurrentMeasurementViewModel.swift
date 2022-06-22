/*
 * Copyright 2018-2021 Cyface GmbH
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

/**
 The view model for the currently active measurement display.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 2.0.0
 */
class CurrentMeasurementViewModel {
    /// Formatter used to display the current measurement duration
    private var formatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        return formatter
    }
    /// A reference to the model of this MVVM
    private let currentMeasurement: MeasurementModel
    /// The label of the current measurement, displayed as title of the view
    var currentMeasurementLabel: String {
        guard let measurement = currentMeasurement.measurement else {
            fatalError("No current measurement!")
        }
        let localizedMeasurement = NSLocalizedString("measurementTitleOnCurrentlyCapturedMeasurement",
                                                     comment: "Title used for a measurement while showing information during capturing.")
        return "\(localizedMeasurement) \(measurement.identifier)"
    }
    /// The image to show for the current fix status
    var hasFix: UIImage {
        if currentMeasurement.hasFix {
            return #imageLiteral(resourceName: "gps-available")
        } else {
            return #imageLiteral(resourceName: "gps-not-available")
        }
    }
    /// The current distance to display for the active measurement
    var distance: String {
        guard let distance = currentMeasurement.distance else {
            return String(format: "%.2f m", 0.0)
        }

        if distance < 1_000.0 {
            return String(format: "%.2f m", distance)
        } else {
            return String(format: "%.2f km", distance/1000.0)
        }
    }
    /// The current speed to display for the active measurement
    var speed: String {
        guard let speed = currentMeasurement.speed else {
            return String(format: "%.2f km/h", 0.0)
        }

        return String(format: "%.2f km/h", speed/3.6)
    }
    /// The current time elapsed capturing the active measurement
    var timestamp: String {
        guard let time = formatTimeInterval() else {
            fatalError("Unable to create time representation!")
        }

        return time
    }
    /// The current longitude of the last geo location captured for the active measurement
    var lastLon: String {
        guard let lastLon = currentMeasurement.lastLon else {
            return String(format: "%.2f", 0.0)
        }

        return String(format: "%.2f", lastLon)
    }
    /// The current latitude of the last geo Location caputred for the active measurement
    var lastLat: String {
        guard let lastLat = currentMeasurement.lastLat else {
            return String(format: "%.2f", 0.0)
        }

        return String(format: "%.2f", lastLat)
    }
    /// The modality used for the current measurement
    var measurementContext: Modality? {
        guard let context = currentMeasurement.context else {
            return nil
        }
        return context
    }
    /// The device wide unique identifier of the active measurement
    var identifier: Int64? {
        return currentMeasurement.identifier
    }

    /**
     Creates a new view model for the current measurement

     - Parameter currentMeasurement: The current measurement to create the view model for
     */
    public init(_ currentMeasurement: MeasurementModel) {
        self.currentMeasurement = currentMeasurement
    }

    /**
     Changes the geo location sensor fix status to the provided new value

     - Parameter to: The status to change to
     */
    func changeFixStatus(to newStatus: Bool) {
        currentMeasurement.hasFix = newStatus
    }

    func finish() -> TableCellViewModel {
        return TableCellViewModel(model: currentMeasurement)
    }

    /**
     Formats the duration of the active measurement into a human readable representation

     - Returns: A human readable representation of the duration of the current time interval
     */
    private func formatTimeInterval() -> String? {
        guard let initialTimestamp = currentMeasurement.initialTimestamp, let currentTimestamp = currentMeasurement.timestamp else {
            return formatter.string(from: 0)
        }
        let timeDifferenceInMilliseconds = currentTimestamp - initialTimestamp
        let timeDifferenceInSeconds = timeDifferenceInMilliseconds / 1000
        let elapsedTimeInSeconds = TimeInterval(timeDifferenceInSeconds)
        return formatter.string(from: elapsedTimeInSeconds)
    }
}
