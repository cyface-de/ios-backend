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
            ControlBar(viewModel: viewModel)
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
            dataStoreStack: MockDataStoreStack(),
            dataStorageInterval: 5.0
        )
        )

        LiveView(viewModel: LiveViewModel(
            measurementState: .running,
            dataStoreStack: MockDataStoreStack(),
            dataStorageInterval: 5.0
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
 A view showing focused details such as the current position or speed of the active measurement.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
struct LiveDetailsView: View {
    @ObservedObject var viewModel: LiveViewModel
    

    var body: some View {
        TabView {
           MainMap()
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
    }
}