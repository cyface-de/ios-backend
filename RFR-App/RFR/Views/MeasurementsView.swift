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
import DataCapturing
import Combine

/**
 A view showing the lists of measurements capture by this device.
 
 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
struct MeasurementsView: View {
    @ObservedObject var viewModel: MeasurementsViewModel

    var body: some View {
        VStack {
            if let error = viewModel.error {
                ErrorView(error: error)
            } else if viewModel.isLoading {
                ProgressView {
                    Text("Bitte warten!")
                }
            } else {
                List {
                    ForEach(viewModel.measurements) {measurement in
                        NavigationLink(destination: MeasurementView(
                            viewModel: MeasurementViewViewModel(
                                dataStoreStack: viewModel.dataStoreStack,
                                measurement: measurement
                            ))) {
                            MeasurementCell(viewModel: MeasurementCellViewModel(measurement: measurement))
                        }
                    }
                }
            }
        }
    }
}

/// Some example data to use for testing views depending on a `Measurement`.
let exampleMeasurements = [
    Measurement(id: 1, name: "Fahrt zu Oma", distance: 3.0, startTime: Date(), synchronizationState: .synchronizable),
    Measurement(id: 2, name: "Arbeit", distance: 10.0, startTime: Date(), synchronizationState: .synchronizing),
    Measurement(id: 3, name: "Supermarkt", distance: 2.3, startTime: Date(), synchronizationState: .synchronized)
]

#if DEBUG
struct MeasurementsView_Previews: PreviewProvider {
    static var previews: some View {
        MeasurementsView(
            viewModel: MeasurementsViewModel(
                dataStoreStack: MockDataStoreStack(),
                uploadPublisher: PassthroughSubject<UploadStatus, Never>()
            )
        )
    }
}
#endif
