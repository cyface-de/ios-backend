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
 A view showing the lists of measurements capture by this device.
 
 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
struct MeasurementsView: View {
    /// The measurements displayed by this view.
    var measurements: [Measurement]
    
    var body: some View {
        VStack {
            HStack {
                Text("Fahrten")
                    .font(.largeTitle)
                Spacer()
            }

            List {
                ForEach(measurements) {measurement in
                    NavigationLink(destination: MeasurementView(viewModel: MeasurementViewViewModel())) {
                        MeasurementCell(viewModel: MeasurementCellViewModel(measurement: measurement))
                    }
                }
            }
        }
    }
}

struct MeasurementsView_Previews: PreviewProvider {
    static var previews: some View {
        MeasurementsView(measurements: exampleMeasurements)
    }
}
