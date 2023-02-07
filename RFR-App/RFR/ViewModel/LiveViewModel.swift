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

/**
 The view model for the live view showing the current capturing session and providing buttons to control it.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - SeeAlso: ``LiveView``
 */
struct LiveViewModel {
    /// How to display the current speed of the user.
    var speed: String
    /// How to display the average speed of the user.
    var averageSpeed: String
    /// The state the active ``Measurement`` is in.
    var measurementState: MeasurementState
    /// The current position in geographic coordinates of longitude and latitude.
    var position: (Double, Double)
    /// The name to display for this ``Measurement``.
    var measurementName: String
    /// How to display the distance already travelled during this ``Measurement``.
    var distance: String
    /// How to display the duration this ``Measurement`` has already taken.
    var duration: String
    /// How to display the current rise during the active ``Measurement``.
    var rise: String
    /// How to display the avoided emissions during the active ``Measurement``.
    var avoidedEmissions: String
}

/**
All the states a measurement may be in. The UI decides which elements to show based on this state.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
enum MeasurementState {
    /// The ``Measurement`` is active at the moment.
    case running
    /// The ``Measurement`` is paused at the moment.
    case paused
    /// The ``Measurement`` is stopped. No ``Measurement`` is currently active.
    case stopped
}

/// Some example data used to render previews of the UI.
let viewModelExample = LiveViewModel(speed: "21 km/h", averageSpeed: "15 km/h", measurementState: .stopped, position: (51.507222, -0.1275), measurementName: "Fahrt 23", distance: "7,4 km", duration: "00:21:04", rise: "732 m", avoidedEmissions: "0,7 kg")
