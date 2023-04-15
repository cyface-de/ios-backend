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
import SwiftUI

/**
 The view model used by a single measurement cell in the list overview of all the measurements.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - SeeAlso: ``MeasurementCell`
 */
class MeasurementCellViewModel {
    static let distanceFormatter = {
        let nf = NumberFormatter()
        nf.minimumFractionDigits = 1
        nf.maximumFractionDigits = 3
        nf.multiplier = 0.001

        return nf
    }()
    /// The ``Measurement`` displayed by the cell.
    let measurement: Measurement
    /// Detail information about the displayed ``Measurement``.
    var details: String {
        guard let formattedDistance = MeasurementCellViewModel.distanceFormatter.string(from: measurement.distance as NSNumber) else {
            fatalError()
        }

        return "\(measurement.startTime.formatted()) (\(formattedDistance) km)"
    }
    /// The symbol showing the current synchronization status of the ``Measurement``.
    @ViewBuilder var synchedSymbol: some View {
        switch measurement.synchronizationState {
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

    /// Create a new view model for the provided ``Measurement``.
    init(measurement: Measurement) {
        self.measurement = measurement
    }
}
