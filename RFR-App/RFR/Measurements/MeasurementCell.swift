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
import MapKit

/**
A single row in the measurements overview displaying all the measurements in a list.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - SeeAlso: ``MeasurementsView``
 */
struct MeasurementCell: View {
    /// The view model containing all information from a measurement required to display a single row in the measurements overview.
    var measurement: Measurement

    var body: some View {
        VStack(alignment: .leading) {
            Text("\(measurement.id)) \(measurement.title)")
                .font(.headline)
            HStack {
                Text("\(measurement.details)")
                Spacer()
                measurement.synchedSymbol.padding([.trailing])
            }
        }
    }
}

struct MeasurementCell_Previews: PreviewProvider {
    static let measurements = [
        Measurement(
            id: 0,
            startTime: Date(timeIntervalSince1970: 10_000),
            synchronizationState: .synchronizable,
            _maxSpeed: 10.0,
            _meanSpeed: 10.0,
            _distance: 10.0,
            _duration: 5_000,
            _inclination: 5.0,
            _lowestPoint: 0.0,
            _highestPoint: 2.0,
            _avoidedEmissions: 2.0,
            heightProfile: [
                Altitude(
                    id: 0,
                    timestamp: Date(timeIntervalSince1970: 10_000),
                    height: 4.0
                ),
                Altitude(
                    id: 1,
                    timestamp: Date(timeIntervalSince1970: 10_100),
                    height: 7.2
                )
            ],
            region: MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.75155, longitude: 11.97411), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)),
            track: [
            ]
        ),
        Measurement(
            id: 1,
            startTime: Date(timeIntervalSince1970: 20_000),
            synchronizationState: .synchronizing,
            _maxSpeed: 20.0,
            _meanSpeed: 20.0,
            _distance: 20.0,
            _duration: 10_000,
            _inclination: 10.0,
            _lowestPoint: 1.0,
            _highestPoint: 4.0,
            _avoidedEmissions: 4.0,
            heightProfile: [
                Altitude(
                    id: 3,
                    timestamp: Date(timeIntervalSince1970: 20_100),
                    height: 3.5
                ),
                Altitude(
                    id: 4,
                    timestamp: Date(timeIntervalSince1970: 20_200),
                    height: 5.4
                )
            ],
            region: MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.75155, longitude: 11.97411), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)),
            track: [
            ]
        )
    ]
    
    static var previews: some View {
        MeasurementCell(measurement: measurements[0])
        MeasurementCell(measurement: measurements[1])
    }
}
