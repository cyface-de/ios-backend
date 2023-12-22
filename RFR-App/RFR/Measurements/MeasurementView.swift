/*
 * Copyright 2023 Cyface GmbH
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
import Charts
import MapKit

/**
 A view showing the details about a single measurement.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.2
 */
struct MeasurementView: View {
    /// The view model used by this view to get the information necessary to display a measurement.
    @ObservedObject var measurement: Measurement

    var body: some View {
        TabView {
            List {
                Section(header: Text("Geschwindigkeit")) {
                    KeyValueView(key: "Max", value: .constant(measurement.speed))
                }
                Section(header: Text("Strecke")) {
                    KeyValueView(key: "Distanz", value: .constant(measurement.distance))
                    KeyValueView(key: "Dauer", value: .constant(measurement.duration))
                }
                Section(header: Text("Höhenprofil")) {
                    Chart(measurement.heightProfile) {
                        LineMark(
                            x: .value("Zeit", $0.timestamp),
                            y: .value("Höhe", $0.height)
                        )
                    }.padding()
                    KeyValueView(key: "Anstieg", value: .constant(measurement.inclination))
                    KeyValueView(key: "Tiefster Punkt", value: .constant(measurement.lowestPoint))
                    KeyValueView(key: "Höchster Punkt", value: .constant(measurement.highestPoint))
                }
                Section(header: Text("Vermiedener CO\u{2082} Ausstoß")) {
                    Text(measurement.avoidedEmissions)
                }
            }.tabItem {
                Image(systemName: "chart.xyaxis.line")
                Text("Statistiken")
            }

            MapView(
                region: measurement.region,
                lineCoordinates: measurement.track
            )
                .frame(width: 400, height: 300)
                .tabItem {
                    Image(systemName: "map")
                    Text("Karte")
                }
        }
        .navigationTitle(measurement.title)
    }
}

#if DEBUG
struct MeasurementView_Previews: PreviewProvider {
    static var  measurement: Measurement {
        let ret = Measurement(
            id: 0,
            startTime: Date(timeIntervalSince1970: 10_000),
            synchronizationState: .synchronized,
            _maxSpeed: 10.0,
            _meanSpeed: 10.0,
            _distance: 200.0,
            _duration: 5_000,
            _inclination: 20.0,
            _lowestPoint: 0.0,
            _highestPoint: 400.0,
            _avoidedEmissions: 45.0,
            heightProfile: [
                Altitude(
                    id: 0,
                    timestamp: Date(timeIntervalSince1970: 10_000),
                    height: 5.0
                ),
                Altitude(
                    id: 1,
                    timestamp: Date(timeIntervalSince1970: 10_100),
                    height: 4.5
                )
            ],
            region: MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.75155, longitude: 11.97411), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)),
            track: [
            ]
        )
        return ret
    }

    static var previews: some View {
        MeasurementView(
            measurement: measurement
        )
    }
}
#endif
