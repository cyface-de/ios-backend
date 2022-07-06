//
//  CurrentMeasurementView.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 20.04.22.
//

import SwiftUI

struct CurrentMeasurementView: View {
    @EnvironmentObject var appState: ApplicationState

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("GPS Fix")
                    .lineLimit(1)
                Text("Distance")
                    .lineLimit(1)
                Text("Speed")
                    .lineLimit(1)
            }.padding()
            Spacer()

            VStack {
                if appState.hasFix {
                    Image("gps-available")
                } else {
                    Image("gps-not-available")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 15.0)
                }
                Text(appState.tripDistance, format: .number)
                Text(appState.speed, format: .number)
            }.padding()

            VStack(alignment: .leading) {
                Text("Duration")
                    .lineLimit(1)
                Text("Latitude")
                    .lineLimit(1)
                Text("Longitude")
                    .lineLimit(1)
            }.padding()
            Spacer()

            VStack {
                Text(appState.duration, format: .number)
                Text(appState.latitude, format: .number)
                Text(appState.longitude, format: .number)
            }.padding()
        }.frame(maxWidth: .infinity)
    }
}

struct CurrentMeasurementView_Previews: PreviewProvider {
    static var previews: some View {
        CurrentMeasurementView()
            .previewDevice("iPod touch (7th generation)")
            .previewInterfaceOrientation(.portraitUpsideDown)
            .environmentObject(ApplicationState(settings: PreviewSettings()))

        CurrentMeasurementView()
            .previewDevice("iPhone 12")
            .previewInterfaceOrientation(.portraitUpsideDown)
            .environmentObject(ApplicationState(settings: PreviewSettings()))
    }
}
