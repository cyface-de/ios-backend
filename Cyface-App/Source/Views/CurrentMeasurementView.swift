//
//  CurrentMeasurementView.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 20.04.22.
//

import SwiftUI

struct CurrentMeasurementView: View {
    @EnvironmentObject var appState: ApplicationState
    var timeFormatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()

        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text("GPS Fix")
                        .lineLimit(1)
                    Spacer()
                    Image(appState.hasFix ? "gps-available" : "gps-not-available")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 15.0)

                }
                Spacer()
                HStack {
                    Text("Distance")
                        .lineLimit(1)
                    Spacer()
                    Text(appState.tripDistance, format: .number)
                        .lineLimit(1)
                }
                Spacer()
                HStack {
                    Text("Speed")
                        .lineLimit(1)
                    Spacer()
                    Text(appState.speed, format: .number)
                        .lineLimit(1)
                }
            }.frame(maxHeight: .infinity)
            VStack {
                HStack(alignment: .top) {
                    Text("Duration")
                        .lineLimit(1)
                    Spacer()
                    Text(timeFormatter.string(from: abs(appState.duration)) ?? "0s")
                        .lineLimit(1)
                }
                Spacer()
                HStack {
                    Text("Latitude")
                        .lineLimit(1)
                    Spacer()
                    Text(appState.latitude, format: .number)
                        .lineLimit(1)
                }
                Spacer()
                HStack(alignment: .bottom) {
                    Text("Longitude")
                        .lineLimit(1)
                    Spacer()
                    Text(appState.longitude, format: .number)
                        .lineLimit(1)
                }
            }
        }
    }
}

struct CurrentMeasurementView_Previews: PreviewProvider {

    static var appState: ApplicationState {
        let ret = ApplicationState(settings: PreviewSettings())
        ret.duration = 200

        return ret
    }

    static var previews: some View {
        CurrentMeasurementView()
            .previewDevice("iPod touch (7th generation)")
            .previewInterfaceOrientation(.portraitUpsideDown)
            .environmentObject(appState)

        CurrentMeasurementView()
            .previewDevice("iPhone 12")
            .previewInterfaceOrientation(.portraitUpsideDown)
            .environmentObject(appState)
    }
}
