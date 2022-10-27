/*
 * Copyright 2022 Cyface GmbH
 *
 * This file is part of the Cyface SDK for iOS.
 *
 * The Cyface SDK for iOS is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Cyface SDK for iOS is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Cyface SDK for iOS. If not, see <http://www.gnu.org/licenses/>.
 */

import SwiftUI

/// A view showing information about the currently captured measurement.
///
/// It shows details about the GPS fix, duration of the measurement, current location, speed and distance traveled.
///
/// - author: Klemens Muthmann
/// - version: 1.0.0
/// - since: 4.0.0
struct CurrentMeasurementView: View {
    /// The view model used to hold the state of the currently captured measurement.
    @StateObject var viewModel: CurrentMeasurementViewModel

    /// Create a new view for the current measurement, with an initial view model.
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
                        .frame(height: 20.0)

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
        .alert("Error", isPresented: $viewModel.hasError, actions: {
            // actions
        }, message: {
            Text(viewModel.errorMessage ?? "")
        })
    }
}

struct CurrentMeasurementView_Previews: PreviewProvider {

    static var appState: ApplicationState {
        let ret = ApplicationState(settings: PreviewSettings())
        //ret.duration = 200

        return ret
    }

    static var errorModel: CurrentMeasurementViewModel {
        let ret = CurrentMeasurementViewModel(appState: appState)
        ret.hasError = true
        ret.errorMessage = "Some error message!"

        return ret
    }

    static var previews: some View {
        CurrentMeasurementView(viewModel: CurrentMeasurementViewModel(appState: appState))
            .previewDevice("iPod touch (7th generation)")
            .previewInterfaceOrientation(.portraitUpsideDown)

        CurrentMeasurementView(viewModel: CurrentMeasurementViewModel(appState: appState))
            .previewDevice("iPhone 12")
            .previewInterfaceOrientation(.portraitUpsideDown)

        CurrentMeasurementView(viewModel: CurrentMeasurementViewModel(appState: appState))
            .preferredColorScheme(.dark)

        CurrentMeasurementView(viewModel: errorModel)
    }
}
