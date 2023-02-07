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
 The view model used by the page showing details about a single ``Measurement``.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - SeeAlso: ``MeasurementView``
 */
class MeasurementViewViewModel {
    /// The title to display for the ``Measurement``
    var title: String {
        "Fahrt zu Oma"
    }
    /// The height profile data used to display a height graph.
    var heightProfile: [Altitude] {
        [
            Altitude(id: 0, timestamp: Date(timeIntervalSince1970: 1675170395), height: 5.0),
            Altitude(id: 1, timestamp: Date(timeIntervalSince1970: 1675173995), height: 10.2),
            Altitude(id: 2, timestamp: Date(timeIntervalSince1970: 1675177595), height: 15.7),
            Altitude(id: 3, timestamp: Date(timeIntervalSince1970: 1675181195), height: 12.3)
        ]
    }
}
