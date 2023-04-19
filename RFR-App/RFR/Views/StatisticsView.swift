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
 A view showing statistics about all the measurements captured by this device.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
struct StatisticsView: View {
    @ObservedObject var viewModel: Measurements

    var body: some View {
        VStack {
            List {
                
                Section(header: Text("Maximale Strecke")) {
                    KeyValueView(key: "Distanz", value: "\(viewModel.maxDistance) (\u{2205} \(viewModel.meansDistance)")
                    KeyValueView(key: "Dauer", value: "\(viewModel.summedDuration) (\u{2205} \(viewModel.meanDuration))")
                }
                
                Section(header: Text("Höhe")) {
                    KeyValueView(key: "Tiefster Punkt", value: viewModel.lowestPoint)
                    KeyValueView(key: "Höchster Punkt", value: viewModel.highestPoint)
                    KeyValueView(key: "Anstieg", value: "max \(viewModel.maxIncline) (\u{2205} \(viewModel.meanIncline))")
                }
                
                Section(header: Text("Vermiedener CO\u{2082} Ausstoß")) {
                    KeyValueView(key: "Gesamt", value: viewModel.avoidedEmissions)
                    KeyValueView(key: "Maximal", value: "\(viewModel.maxAvoidedEmissions) (\u{2205} \(viewModel.meanAvoidedEmissions))")
                }
            }
        }
    }
}

#if DEBUG
struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView(viewModel: Measurements(coreDataStack: MockDataStoreStack()))
    }
}
#endif

