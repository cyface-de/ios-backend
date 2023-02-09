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
 The main application view allowing to switch subviews using a `TabView`.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
struct MainView: View {
    var body: some View {
        NavigationStack {
            TabView {
                MeasurementsView(measurements: exampleMeasurements)
                    .tabItem {
                        Image(systemName: "square.3.layers.3d")
                        Text("Fahrten")
                            .font(.footnote)
                    }
                LiveView(viewModel: viewModelExample)
                    .tabItem {
                        Image(systemName: "play")
                        Text("Live")
                    }
                StatisticsView()
                    .tabItem {
                        Image(systemName: "chart.xyaxis.line")
                        Text("Statistiken")
                            .font(.footnote)
                    }
            }
            .toolbar {
                Button(action: {print("Daten übertragen")}) {
                    VStack {
                        Image(systemName: "icloud.and.arrow.up")
                        Text("Daten übertragen")
                            .font(.footnote)
                    }
                }
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
