//
//  CurrentMeasurementView.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 20.04.22.
//

import SwiftUI

struct CurrentMeasurementView: View {
    @StateObject var currentMeasurement = CurrentMeasurement()

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("GPS Fix")
                Text("Trip Distance")
                Text("Speed")
            }.padding()
            Spacer()

            VStack {
                if currentMeasurement.hasFix {
                    Image("gps-available")
                } else {
                    Image("gps-not-available")
                }
                Text(currentMeasurement.tripDistance, format: .number)
                Text(currentMeasurement.speed, format: .number)
            }.padding()

            VStack(alignment: .leading) {
                Text("Duration")
                Text("Latitude")
                Text("Longitude")
            }.padding()
            Spacer()

            VStack {
                Text(currentMeasurement.duration, format: .number)
                Text(currentMeasurement.latitude, format: .number)
                Text(currentMeasurement.longitude, format: .number)
            }.padding()
        }.frame(maxWidth: .infinity)
    }
}

struct CurrentMeasurementView_Previews: PreviewProvider {
    static var previews: some View {
        CurrentMeasurementView()
            .previewInterfaceOrientation(.portraitUpsideDown)
    }
}
