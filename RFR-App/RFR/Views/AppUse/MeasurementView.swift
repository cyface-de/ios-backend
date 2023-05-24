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
import Charts
import MapKit

/**
 A view showing the details about a single measurement.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
struct MeasurementView: View {
    /// The view model used by this view to get the information necessary to display a measurement.
    @ObservedObject var viewModel: MeasurementViewViewModel
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.75155, longitude: 11.97411), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))

    var body: some View {
        if let error = viewModel.error {
            ErrorView(error: error)
        } else if viewModel.isInitialized {
            TabView {
                List {
                    Section(header: Text("Geschwindigkeit")) {
                        KeyValueView(key: "Max", value: "\(viewModel.maxSpeed) (\u{2205} \(viewModel.meanSpeed))")
                    }
                    Section(header: Text("Strecke")) {
                        KeyValueView(key: "Distanz", value: viewModel.distance)
                        KeyValueView(key: "Dauer", value: viewModel.duration)
                    }
                    Section(header: Text("Höhenprofil")) {
                        Chart(viewModel.heightProfile) {
                            LineMark(
                                x: .value("Zeit", $0.timestamp),
                                y: .value("Höhe", $0.height)
                            )
                        }.padding()
                        KeyValueView(key: "Anstieg", value: viewModel.inclination)
                        KeyValueView(key: "Tiefster Punkt", value: viewModel.lowestPoint)
                        KeyValueView(key: "Höchster Punkt", value: viewModel.highestPoint)
                    }
                    Section(header: Text("Vermiedender CO\u{2082} Ausstoß")) {
                        Text(viewModel.avoidedEmissions)
                    }
                }.tabItem {
                    Image(systemName: "chart.xyaxis.line")
                    Text("Statistiken")
                }

                Map(coordinateRegion: $region)
                    .frame(width: 400, height: 300)
                    .tabItem {
                        Image(systemName: "map")
                        Text("Karte")
                    }
            }
            .navigationTitle(viewModel.title)
        } else {
            ProgressView {
                Text("Bitte warten")
            }
        }
    }
}

#if DEBUG
struct MeasurementView_Previews: PreviewProvider {
    static var previews: some View {
        MeasurementView(
            viewModel: MeasurementViewViewModel(
                dataStoreStack: MockDataStoreStack(),
                measurement: Measurement(
                    id: 0,
                    name: "Titel",
                    distance: 10.2,
                    startTime: Date(),
                    synchronizationState: .synchronizable
                )
            )
        )
    }
}
#endif
