/*
 * Copyright 2023 Cyface GmbH
 *
 * This file is part of the Ready for Robots App.
 *
 * The Ready for Robots App is free software: you can redistribute it and/or modify
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
import DataCapturing

/**
 A view showing controls for the active measurement.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
struct ControlBar: View {
    @ObservedObject var viewModel: LiveViewModel
    @State var error: Error?

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
    }
}

#if DEBUG
struct ControlBar_Previews: PreviewProvider {
    static var previews: some View {
        ControlBar(
            viewModel: LiveViewModel(
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

        ControlBar(
            viewModel: LiveViewModel(
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
            )
        )

        ControlBar(
            viewModel: LiveViewModel(
                measurementState: .paused,
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
    }
}
#endif
