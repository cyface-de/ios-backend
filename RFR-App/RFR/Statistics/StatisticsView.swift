/*
 * Copyright 2023-2024 Cyface GmbH
 *
 * This file is part of the Ready for Robots iOS App.
 *
 * The Ready for Robots iOS App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Ready for Robots iOS App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Ready for Robots iOS App. If not, see <http://www.gnu.org/licenses/>.
 */
import SwiftUI
import DataCapturing

/**
 A view showing statistics about all the measurements captured by this device.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.2
 */
struct StatisticsView: View {
    /// The view model for the measurements already captured by this application.
    @ObservedObject var viewModel: MeasurementsViewModel

    var body: some View {
        VStack {
            List {
                Section(header: Text("Maximale Strecke")) {
                    KeyValueView(
                        key: "Distanz",
                        value: $viewModel.distance
                    )
                    KeyValueView(
                        key: "Dauer",
                        value: $viewModel.duration
                    )
                }
                
                Section(header: Text("Höhe")) {
                    KeyValueView(
                        key: "Tiefster Punkt",
                        value: $viewModel.lowestPoint
                    )
                    KeyValueView(
                        key: "Höchster Punkt",
                        value: $viewModel.highestPoint
                    )
                    KeyValueView(
                        key: "Anstieg",
                        value: $viewModel.incline
                    )
                }
                
                Section(header: Text("Vermiedener CO\u{2082} Ausstoß")) {
                    KeyValueView(
                        key: "Gesamt",
                        value: $viewModel.avoidedEmissions
                    )
                    KeyValueView(
                        key: "Maximal",
                        value: $viewModel.maxAvoidedEmissions
                    )
                    KeyValueView(
                        key: "mean",
                        value: $viewModel.meanAvoidedEmissions
                    )
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    StatisticsView(
        viewModel: MeasurementsViewModel(
            dataStoreStack: MockDataStoreStack()
        )
    )
}
#endif
