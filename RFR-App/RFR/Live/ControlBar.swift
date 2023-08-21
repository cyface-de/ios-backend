//
//  ControlBar.swift
//  RFR
//
//  Created by Klemens Muthmann on 15.06.23.
//

import SwiftUI

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
        }
    }
}

#if DEBUG
struct ControlBar_Previews: PreviewProvider {
    static var previews: some View {
        ControlBar(
            viewModel: LiveViewModel(
                dataStoreStack: MockDataStoreStack(),
                dataStorageInterval: 5.0
            )
        )

        ControlBar(
            viewModel: LiveViewModel(
                measurementState: .running,
                dataStoreStack: MockDataStoreStack(),
                dataStorageInterval: 5.0
            )
        )

        ControlBar(
            viewModel: LiveViewModel(
                measurementState: .paused,
                dataStoreStack: MockDataStoreStack(),
                dataStorageInterval: 5.0
            )
        )
    }
}
#endif
