//
//  ContentView.swift
//  RFR
//
//  Created by Klemens Muthmann on 26.01.23.
//
import MapKit
import SwiftUI

struct LiveView: View {
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

struct ControlBarView: View {
    var body: some View {
        HStack {
            Button(action: onPlayPausePressed) {
                Image(systemName: "playpause.fill")
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            Button(action: onStopPressed){
                Image(systemName: "stop.fill")
            }
            .frame(maxWidth: .infinity, minHeight: 44)
        }
    }

    // TODO: Move to ViewModel
    func onPlayPausePressed() {
        print("play/pause")
    }

    func onStopPressed() {
        print("stop")
    }
}

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
                Image(systemName: "play")
                Text("Live")
            }
        }
    }
}
