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

/**
 A struct representing a measurement as required by the user interface of the application.`

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
struct Measurement: Identifiable {
    /// The identifier to use this object as part of a `List` or a `ForEach`. This may be the system wide unique measurement identifier, also used by the database.
    let id: Int64
    /// The name of this measurement used to display it on screen.
    let name: String
    /// The total distance travelled while measuring this.
    let distance: Double
    /// The time and date at which this measurement started.
    let startTime: Date
    /// Whether this measurement has been synchronized with the cloud. This is `true` if the measurement was synchronized and `false otherwise.`
    let synchronized: Bool
}
