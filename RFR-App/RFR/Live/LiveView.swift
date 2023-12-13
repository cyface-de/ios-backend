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
import DataCapturing

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
            dataStoreStack: MockDataStoreStack(
                persistenceLayer: MockPersistenceLayer(
                    measurements: [
                        FinishedMeasurement(identifier: 0),
                        FinishedMeasurement(identifier: 1),
                        FinishedMeasurement(identifier: 2)
                    ]
                )
            ),
            dataStorageInterval: 5.0
        )
        )

        LiveView(viewModel: LiveViewModel(
            measurementState: .running,
            dataStoreStack: MockDataStoreStack(
                persistenceLayer: MockPersistenceLayer(
                    measurements: [
                        FinishedMeasurement(identifier: 0),
                        FinishedMeasurement(identifier: 1),
                        FinishedMeasurement(identifier: 2)
                    ]
                )
            ),
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
                Text("Geschwindigkeit", comment: "Label for the current speed, the user is going during a running measurement.")
                Spacer()
                Text("\(viewModel.speed) (\u{2205} \(viewModel.averageSpeed))", comment: "Value for the current speed, the user is going during a running measurement.")
            }
            HStack {
                Text("Strecke", comment: "Label for the length of the route the user has been going during the running measurement.")
                Spacer()
                Text(viewModel.distance)
            }
            HStack {
                Text("Fahrtzeit", comment: "Label for the time the user has spent, with the running measurement.")
                Spacer()
                Text(viewModel.duration)
            }
            HStack {
                Text("Anstieg", comment: "Label for the ascent so far of the running measurement.")
                Spacer()
                Text(viewModel.rise)
            }
            HStack {
                Text("Vermiedener CO\u{2082} Ausstoß", comment: "Label for the so far avoided emissions during the running measurement in comparison to going the same route by car.")
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
                Text("Position", comment: "Tab label for selecting to show the map view during a measurement.")
            }
            VStack {
                Text("Geschwindigkeit", comment: "Label for the current speed shown to the user during an active measurement.")
                    .font(.largeTitle)
                Text(viewModel.speed)
                    .font(.system(size: 36))
                    .fontWeight(.bold)
            }
            .tabItem {
                Image(systemName: "speedometer")
                Text("Geschwindigkeit", comment: "Tab label for showing the current speed instead of a map during a measurement.")
            }
        }
    }
}
