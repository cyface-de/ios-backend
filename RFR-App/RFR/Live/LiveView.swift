/*
 * Copyright 2023-2024 Cyface GmbH
 *
 * This file is part of the Ready for Robots iOS App.
 *
 * The Ready for Robots iOS App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Ready for Robots iOS App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Ready for Robots iOS App. If not, see <http://www.gnu.org/licenses/>.
 */
import SwiftUI
import DataCapturing

/**
 A view for showing information about the current measurement and providing controls for that

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since 3.1.2
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

    /// Live details should only be visible if a measurement is running and hidden if not.
    /// This method provides the information on whether to show such live details or not.
    /// If it returns `true` the UI should show them, otherwise they need to stay hidden.
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
#Preview("Stopped") {
    let mockDataStoreStack = MockDataStoreStack()
    let measurementsViewModel = MeasurementsViewModel(dataStoreStack: mockDataStoreStack)

    return LiveView(viewModel: LiveViewModel(
        speed: 21.0,
        averageSpeed: 15.0,
        measurementState: .stopped,
        dataStoreStack: MockDataStoreStack(),
        dataStorageInterval: 5.0, 
        measurementsViewModel: measurementsViewModel
    )
    )
}

#Preview("Running") {
    let mockDataStoreStack = MockDataStoreStack()
    let measurementsViewModel = MeasurementsViewModel(dataStoreStack: mockDataStoreStack)

    return LiveView(viewModel: LiveViewModel(
        measurementState: .running,
        dataStoreStack: MockDataStoreStack(),
        dataStorageInterval: 5.0, 
        measurementsViewModel: measurementsViewModel
    ))
}
#endif

/**
 A view showing live statistics about the current measurement.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since 3.1.2
 */
struct LiveStatisticsView: View {
    /// A view model containing the most recent values reported from the device sensors during a running measurement.
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
                Text(viewModel.inclination)
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
 - Since: 3.2.1
 */
struct LiveDetailsView: View {
    /// The view model containing the information about the currently running measurement.
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
