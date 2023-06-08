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
import MapKit
import CoreLocation
import SwiftUI

/**
 A view for showing information about the current measurement and providing controls for that

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
struct LiveView: View {
    /// The view model used by this `View`.
    @ObservedObject var viewModel: LiveViewModel

    var body: some View {
        VStack {
            LiveDetailsView(viewModel: viewModel)
            if showLiveDetails(viewModel: viewModel) {
                Divider()
                LiveStatisticsView(viewModel: viewModel)
                Spacer()
            }
            Divider()
            ControlBarView(viewModel: viewModel)
                .padding()
        }
    }

    func showLiveDetails(viewModel: LiveViewModel) -> Bool {
        switch viewModel.measurementState {
        case .stopped:
            return false
        case .running:
            return true
        case .paused:
            return true
        }
    }
}

#if DEBUG
struct LiveView_Previews: PreviewProvider {
    static var previews: some View {
        LiveView(viewModel: LiveViewModel(
            speed: 21.0,
            averageSpeed: 15.0,
            measurementState: .stopped,
            dataStoreStack: MockDataStoreStack()
            )
        )

        LiveView(viewModel: LiveViewModel(
            measurementState: .running,
            dataStoreStack: MockDataStoreStack()
        ))
    }
}
#endif

/**
 A view showing live statistics about the current measurement.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
struct LiveStatisticsView: View {
    @ObservedObject var viewModel: LiveViewModel

    var body: some View {
        VStack(alignment: .leading) {
            Text(viewModel.measurementName).font(.largeTitle)
            HStack {
                Text("Geschwindigkeit")
                Spacer()
                Text("\(viewModel.speed) (\u{2205} \(viewModel.averageSpeed))")
            }
            HStack {
                Text("Strecke")
                Spacer()
                Text(viewModel.distance)
            }
            HStack {
                Text("Fahrtzeit")
                Spacer()
                Text(viewModel.duration)
            }
            HStack {
                Text("Anstieg")
                Spacer()
                Text(viewModel.rise)
            }
            HStack {
                Text("Vermiedener CO\u{2082} Ausstoß")
                Spacer()
                Text(viewModel.avoidedEmissions)
            }
        }
        .padding([.leading, .trailing])
    }
}

/**
 A view showing controls for the active measurement.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
struct ControlBarView: View {
    @ObservedObject var viewModel: LiveViewModel

    var body: some View {
        HStack {
            Button(action: viewModel.onPlayPausePressed) {
                Image(systemName: "playpause.fill")
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            Button(action: viewModel.onStopPressed){
                Image(systemName: "stop.fill")
            }
            .frame(maxWidth: .infinity, minHeight: 44)
        }
    }
}

struct Marker: Identifiable {
    let id = UUID()
    var location: MapMarker
}

/**
 A view showing focused details such as the current position or speed of the active measurement.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
struct LiveDetailsView: View {
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.5515, longitude: 12.2388), span: MKCoordinateSpan( latitudeDelta: 0.9, longitudeDelta: 0.9))
    @ObservedObject var viewModel: LiveViewModel
    @State var markers = [Marker]()

    var body: some View {
        TabView {
            Map(
                coordinateRegion: $region,
                showsUserLocation: true,
                userTrackingMode: .constant(.follow),
                annotationItems: markers
            ) { marker in
                marker.location
            }
                .padding([.top])
                .tabItem {
                    Image(systemName: "map")
                    Text("Position")
                }
            VStack {
                Text("Geschwindigkeit")
                    .font(.largeTitle)
                Text(viewModel.speed)
                    .font(.system(size: 36))
                    .fontWeight(.bold)
            }
            .tabItem {
                Image(systemName: "speedometer")
                Text("Geschwindigkeit")
            }
        }
        .onAppear {
            let schkeuditzData = loadAlleyCatData(fileName: "schkeuditz", ext: "csv")
            let köthenData = loadAlleyCatData(fileName: "köthen", ext: "csv")
            var data = [AlleyCatMarker]()
            data.append(contentsOf: schkeuditzData)
            data.append(contentsOf: köthenData)

            var markers = [Marker]()
            data.forEach { marker in
                markers.append(Marker(location: MapMarker(coordinate: CLLocationCoordinate2D(latitude: marker.latitude, longitude: marker.longitude), tint: .red)))
            }

            self.markers.append(contentsOf: markers)
        }
    }
}
