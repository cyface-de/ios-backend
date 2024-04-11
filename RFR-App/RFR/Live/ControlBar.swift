/*
 * Copyright 2023-2024 Cyface GmbH
 *
 * This file is part of the Ready for Robots App.
 *
 * The Ready for Robots App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Ready for Robots App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Ready for Robots App. If not, see <http://www.gnu.org/licenses/>.
 */
import SwiftUI
import DataCapturing

/**
 A view showing controls for the active measurement.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.2
 */
struct ControlBar: View {
    /// The view model backing this view.
    @ObservedObject var viewModel: LiveViewModel
    /// If an error occured during the measurement, this will have a value and can be displayed to the user.
    @State var error: Error?
    /// This is `true` if an error should be shown and `false` otherwise.
    var isShowingError: Binding<Bool> {
        Binding {
            error != nil
        } set: { _ in
            error = nil
        }
    }

    var body: some View {
        HStack {
            Button(action: {
                do {
                    try viewModel.onPausePressed()
                } catch {
                    self.error = error
                }
            }) {
                Image(systemName: "pause.fill")
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .disabled(MeasurementState.running != viewModel.measurementState)
            .accessibilityIdentifier("de.cyface.rfr.button.pause")

            Button(action: {
                do {
                    try viewModel.onPlayPressed()
                } catch {
                    self.error = error
                }
            }) {
                Image(systemName: "play.fill")
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .disabled(MeasurementState.running == viewModel.measurementState)
            .accessibilityIdentifier("de.cyface.rfr.button.play")

            Button(action: {
                do {
                    try viewModel.onStopPressed()
                } catch {
                    self.error = error
                }
            }) {
                Image(systemName: "stop.fill")
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .disabled(MeasurementState.stopped == viewModel.measurementState)
            .accessibilityIdentifier("de.cyface.rfr.button.stop")
        }
        .alert(
            "error",
            isPresented: isShowingError,
            presenting: error) { error in
                // If you want buttons other than OK, add here
            } message: { error in
                Text(error.localizedDescription)
            }
    }
}

#if DEBUG
#Preview("Stopped") {
    let mockDataStoreStack = MockDataStoreStack()
    let measurementsViewModel = MeasurementsViewModel(dataStoreStack: mockDataStoreStack)

    return ControlBar(
        viewModel: LiveViewModel(
            dataStoreStack: mockDataStoreStack,
            dataStorageInterval: 5.0,
            measurementsViewModel: measurementsViewModel
        )
    )
}

#Preview("Running") {
    let mockDataStoreStack = MockDataStoreStack()
    let measurementsViewModel = MeasurementsViewModel(dataStoreStack: mockDataStoreStack)

    return ControlBar(
        viewModel: LiveViewModel(
            measurementState: .running,
            dataStoreStack: MockDataStoreStack(),
            dataStorageInterval: 5.0,
            measurementsViewModel: measurementsViewModel
        )
    )
}

#Preview("Paused") {
    let mockDataStoreStack = MockDataStoreStack()
    let measurementsViewModel = MeasurementsViewModel(dataStoreStack: mockDataStoreStack)

    return ControlBar(
        viewModel: LiveViewModel(
            measurementState: .paused,
            dataStoreStack: MockDataStoreStack(),
            dataStorageInterval: 5.0,
            measurementsViewModel: measurementsViewModel
        )
    )
}

#Preview("Showing Error") {
    let mockDataStoreStack = MockDataStoreStack()
    let measurementsViewModel = MeasurementsViewModel(dataStoreStack: mockDataStoreStack)

    return ControlBar(
        viewModel: LiveViewModel(
            dataStoreStack: MockDataStoreStack(),
            dataStorageInterval: 5.0,
            measurementsViewModel: measurementsViewModel
        ),
        error: DataCapturingError.isPaused
    )
}
#endif
