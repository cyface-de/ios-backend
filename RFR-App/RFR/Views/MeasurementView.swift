//
//  MeasurementView.swift
//  RFR
//
//  Created by Klemens Muthmann on 26.01.23.
//

import SwiftUI
import Charts
import MapKit

struct MeasurementView: View {
    let viewModel: MeasurementViewViewModel
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))

    var body: some View {
        NavigationStack {
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
}

struct MeasurementView_Previews: PreviewProvider {
    static var previews: some View {
        MeasurementView(viewModel: MeasurementViewViewModel())
    }
}
