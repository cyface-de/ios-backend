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

import SwiftUI

/**
A single row in the measurements overview displaying all the measurements in a list.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - SeeAlso: ``MeasurementsView``
 */
struct MeasurementCell: View {
    /// The view model containing all information from a measurement required to display a single row in the measurements overview.
    var viewModel: MeasurementCellViewModel

    var body: some View {
        VStack(alignment: .leading) {
            Text("\(viewModel.measurement.id)) \(viewModel.measurement.name)")
                .font(.headline)
            HStack {
                Text("\(viewModel.details)")
                Spacer()
                viewModel.synchedSymbol.padding([.trailing])
            }
        }
    }
}

struct MeasurementCell_Previews: PreviewProvider {
    static var previews: some View {
        MeasurementCell(viewModel: MeasurementCellViewModel(measurement: exampleMeasurements[0]))
        MeasurementCell(viewModel: MeasurementCellViewModel(measurement: exampleMeasurements[1]))
    }
}
