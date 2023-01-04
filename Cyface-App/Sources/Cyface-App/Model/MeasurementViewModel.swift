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

/// The MVVM view model for a single list entry in the list of measurements.
///
/// It contains the information shown on screen as well as the current synchronization state, to show appropriate icons.
///
/// - author: Klemens Muthmann
/// - version: 1.0.0
/// - since: 4.0.0
struct MeasurementViewModel: Identifiable {
    /// Flag which is `true` if the data synchroniation has failed and `false` otherwise. If it is true the Ui displays an exclamation mark icon and maybe some information about the error.
    var synchronizationFailed = false
    /// Flag which is `true` if the app is currently synchronizing data and `false` otherwise. This is used to show an acitivity or progress indicator during the upload process.
    var synchronizing = false
    /// The distance of the displayed measurement. This is used to display the length of a measurement for easier disambiguation.
    var distance = 0.0
    /// The distance of the displayed measurement, properly formatted with either meters or kilometers as the unit. depending on the length.
    var formattedDistance: String {
        get {
            distance < 1_000 ? String(format: "%.0f m", distance) : String(format: "%.2f km", distance / 1_000)
        }
    }
    /// The device wide unique identifier of the measurement to display.
    let id: Int64
}
