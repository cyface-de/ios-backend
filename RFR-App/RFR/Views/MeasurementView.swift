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
    let viewModel: MeasurementViewViewModel
    //TODO: Move into the view model.
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.75155, longitude: 11.97411), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))

    var body: some View {
            TabView {
                List {
                    Section(header: Text("Geschwindigkeit")) {
                        KeyValueView(key: "Max", value: "21 km/h (\u{2205} 15 km/h)")
                    }
                    Section(header: Text("Strecke")) {
                        KeyValueView(key: "Distanz", value: "214,2 km")
                        KeyValueView(key: "Dauer", value: "2 T 14 h 12 min")
                    }
                    Section(header: Text("Höhenprofil")) {
                        Chart(viewModel.heightProfile) {
                            LineMark(
                                x: .value("Zeit", $0.timestamp),
                                y: .value("Höhe", $0.height)
                            )
                        }.padding()
                        KeyValueView(key: "Anstieg", value: "2,1 km")
                        KeyValueView(key: "Tiefster Punkt", value: "104 m")
                        KeyValueView(key: "Höchster Punkt", value: "2.203 m")
                    }
                    Section(header: Text("Vermiedender CO\u{2082} Ausstoß")) {
                        Text("1,3 kg")
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
    }
}

struct MeasurementView_Previews: PreviewProvider {
    static var previews: some View {
        MeasurementView(viewModel: MeasurementViewViewModel())
    }
}
