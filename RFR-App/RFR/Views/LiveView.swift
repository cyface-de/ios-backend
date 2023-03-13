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
import SwiftUI

/**
 A view for showing information about the current measurement and providing controls for that

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
struct LiveView: View {
    /// The view model used by this `View`.
    @State var viewModel: LiveViewModel

    var body: some View {
        NavigationStack {
            VStack {
                LiveDetailsView()
                Divider()
                LiveStatisticsView()
                Spacer()
                Divider()
                ControlBarView()
            }
            .padding()
            .navigationBarTitle("Ready for Robots")
        }
    }
}

struct LiveView_Previews: PreviewProvider {
    static var previews: some View {
        LiveView(viewModel: LiveViewModel(speed: "21 km/h", averageSpeed: "15 km/h", measurementState: .stopped, position: (51.507222, -0.1275), measurementName: "Fahrt 23", distance: "7,4 km", duration: "00:21:04", rise: "732 m", avoidedEmissions: "0,7 kg"))
    }
}

/**
A view showing live statistics about the current measurement.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
struct LiveStatisticsView: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Fahrt 23").font(.largeTitle)
            HStack {
                Text("Geschwindigkeit")
                Spacer()
                Text("21 km/h (\u{2205} 15 km/h)")
            }
            HStack {
                Text("Strecke")
                Spacer()
                Text("7,4 km")
            }
            HStack {
                Text("Fahrtzeit")
                Spacer()
                Text("00:21:04")
            }
            HStack {
                Text("Anstieg")
                Spacer()
                Text("732 m")
            }
            HStack {
                Text("Vermiedener CO\u{2082} Ausstoß")
                Spacer()
                Text("0,7 kg")
            }
        }
    }
}

/**
 A view showing controls for the active measurement.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
struct ControlBarView: View {
    let viewModel: ControlBarViewModel = ControlBarViewModel()

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

/**
A view showing focused details such as the current position or speed of the active measurement.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
struct LiveDetailsView: View {
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
    
    var body: some View {
        TabView {
            Map(coordinateRegion: $region)
                .frame(width: 400, height: 300)
                .tabItem {
                    Image(systemName: "map")
                    Text("Position")
                }
            VStack {
                Text("Geschwindigkeit")
                    .font(.largeTitle)
                Text("21 km/h")
                    .font(.system(size: 36))
                    .fontWeight(.bold)
            }
            .tabItem {
                Image(systemName: "speedometer")
                Text("Geschwindigkeit")
            }
        }
    }
}
