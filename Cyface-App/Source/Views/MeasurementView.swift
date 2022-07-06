//
//  MeasurementView.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 17.04.22.
//

import SwiftUI
import DataCapturing

struct MeasurementView: View {

    // @StateObject var measurementsViewModel: MeasurementsViewModel
    @EnvironmentObject var appState: ApplicationState
    @State var selectedModality = Modalities.defaultSelection
    @State var showError = false
    @State var errorMessage = ""
    // TODO: add modality state
    var body: some View {
        VStack {
            ScrollView {
                ForEach($appState.measurements) { $row in
                        MeasurementListView(measurementViewModel: $row)
                    }
            }

            if appState.isCurrentlyCapturing || appState.isPaused {
                CurrentMeasurementView()
            }

            ModalitySelectorView(selectedModality: $selectedModality)

            HStack {
                Button(action: {
                    do {
                        try appState.dcs.start(inMode: selectedModality.dbValue)
                    } catch {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }) {
                    Image("play")
                        .renderingMode(.original)
                        .padding()
                }
                .frame(maxWidth: .infinity)
                .disabled(appState.isCurrentlyCapturing)

                Button(action: {
                    do {
                        try appState.dcs.pause()
                    } catch {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }) {
                    Image("pause")
                        .renderingMode(.original)
                        .padding()
                }
                .frame(maxWidth: .infinity)
                .disabled(appState.isPaused || (!appState.isPaused && !appState.isCurrentlyCapturing))

                Button(action: {
                    do {
                        try appState.dcs.stop()
                    } catch {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }) {
                    Image("stop")
                        .renderingMode(.original)
                        .padding()
                }
                .frame(maxWidth: .infinity)
                .disabled(!appState.isCurrentlyCapturing && !appState.isPaused)
            }
            .frame(maxWidth: .infinity)

            HStack {
                Button(action: {
                    // TODO: Invoke Synchronization here
                }) {
                    Image("upload")
                }
                .padding(10)

                Spacer()
            }
        }
            .navigationBarBackButtonHidden(true)
            .navigationTitle("Measurements")
            .frame(maxWidth: .infinity)
            .alert("Error", isPresented: $showError, actions: {
                // actions
            }, message: {
                Text(errorMessage)
            })
    }
}

struct MeasurementView_Previews: PreviewProvider {
    static var applicationState: ApplicationState {
        let ret = ApplicationState(settings: PreviewSettings())
        ret.isCurrentlyCapturing = true
        ret.measurements = [MeasurementViewModel(distance: 5.0, id: 1), MeasurementViewModel(distance: 6.0, id: 2)]

        return ret
    }

    static var previews: some View {
        MeasurementView().environmentObject(applicationState)
    }
}
