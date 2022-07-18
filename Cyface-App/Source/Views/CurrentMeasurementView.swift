//
//  CurrentMeasurementView.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 20.04.22.
//

import SwiftUI

struct CurrentMeasurementView: View {
    @StateObject var viewModel: CurrentMeasurementViewModel

    init(viewModel: CurrentMeasurementViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text("GPS Fix")
                        .lineLimit(1)
                    Spacer()
                    Image(uiImage: viewModel.hasFix)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 15.0)

                }
                Spacer()
                HStack {
                    Text("Distance")
                        .lineLimit(1)
                    Spacer()
                    Text(viewModel.distance)
                        .lineLimit(1)
                }
                Spacer()
                HStack {
                    Text("Speed")
                        .lineLimit(1)
                    Spacer()
                    Text(viewModel.speed)
                        .lineLimit(1)
                }
            }.frame(maxHeight: .infinity)
            VStack {
                HStack(alignment: .top) {
                    Text("Duration")
                        .lineLimit(1)
                    Spacer()
                    Text(viewModel.duration)
                        .lineLimit(1)
                }
                Spacer()
                HStack {
                    Text("Latitude")
                        .lineLimit(1)
                    Spacer()
                    Text(viewModel.latitude)
                        .lineLimit(1)
                }
                Spacer()
                HStack(alignment: .bottom) {
                    Text("Longitude")
                        .lineLimit(1)
                    Spacer()
                    Text(viewModel.longitude)
                        .lineLimit(1)
                }
            }
        }
    }
}

struct CurrentMeasurementView_Previews: PreviewProvider {

    static var appState: ApplicationState {
        let ret = ApplicationState(settings: PreviewSettings())
        //ret.duration = 200

        return ret
    }

    static var previews: some View {
        CurrentMeasurementView(viewModel: CurrentMeasurementViewModel(appState: appState))
            .previewDevice("iPod touch (7th generation)")
            .previewInterfaceOrientation(.portraitUpsideDown)

        CurrentMeasurementView(viewModel: CurrentMeasurementViewModel(appState: appState))
            .previewDevice("iPhone 12")
            .previewInterfaceOrientation(.portraitUpsideDown)
    }
}
