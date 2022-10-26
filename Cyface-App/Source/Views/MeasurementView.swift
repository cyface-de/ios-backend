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
import DataCapturing

/**
 The main view of the application, combining an overview of all the captured measurements and control elements to run data capturing.

 - author: Klemens Muthmann
 - version: 1.0.0
 */
struct MeasurementView: View {
    /// The current application state.
    @EnvironmentObject var appState: ApplicationState
    /// The authenticator used to login the user. This should contain the currently valid user to login and upload data.
    var authenticator: CredentialsAuthenticator?
    /// The modality selected to capture data.
    @State var selectedModality = Modalities.defaultSelection
    /// If `true` an error message is shown to the user.
    @State var showError = false
    /// The error message to show if `showError` is true.
    @State var errorMessage = ""
    /// If `true` the currently displayed error is dismissed.
    var dismiss = false
    /// This is required to dimiss the view on a non recoverable error.
    /// More explanation here: https://www.hackingwithswift.com/quick-start/swiftui/how-to-make-a-view-dismiss-itself
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            List {
                ForEach($appState.measurements) { $row in
                        MeasurementListView(measurementViewModel: $row)
                    }
                .onDelete(perform: deleteMeasurements)
            }
            .toolbar {
                EditButton()
            }

            if appState.isCurrentlyCapturing || appState.isPaused {
                CurrentMeasurementView(viewModel: CurrentMeasurementViewModel(appState: appState))
                    .fixedSize(horizontal: false, vertical: true)
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
                    Image(systemName: "play.fill")
                        .renderingMode(.original)
                        .foregroundColor(.primary)
                        .font(.system(size: 30))
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
                    Image(systemName: "pause.fill")
                        .renderingMode(.original)
                        .foregroundColor(.primary)
                        .font(.system(size: 30))
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
                    Image(systemName: "stop.fill")
                        .renderingMode(.original)
                        .foregroundColor(.primary)
                        .font(.system(size: 30))
                        .padding()
                }
                .frame(maxWidth: .infinity)
                .disabled(!appState.isCurrentlyCapturing && !appState.isPaused)
            }
            .frame(maxWidth: .infinity)

            HStack {
                Button(action: {
                    appState.sync()
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .frame(alignment: .center)
                .foregroundColor(.primary)
                .padding(5)
                .font(.system(size: 25))

                Spacer()
            }
        }
            .navigationBarBackButtonHidden(true)
            .navigationTitle("Measurements")
            .navigationBarTitleDisplayMode(.inline)
            .frame(maxWidth: .infinity)
            .alert("Error", isPresented: $showError, actions: {
                // actions
            }, message: {
                Text(errorMessage)
            })
            .alert("Error", isPresented: $appState.hasError, actions: {
                // actions
                Button("OK") {
                    if dismiss {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }, message: {
                Text(appState.errorMessage)
            })
            .onAppear() {
                appState.startSynchronization(authenticator: self.authenticator)
            }
            .tint(Color("Cyface-Green"))
    }

    /// Handles calling delete on one or more measurements.
    private func deleteMeasurements(at offsets: IndexSet) {
        do {
            try appState.deleteMeasurements(at: offsets)
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
    }
}

struct MeasurementView_Previews: PreviewProvider {
    static var applicationState: ApplicationState {
        let ret = ApplicationState(settings: PreviewSettings())
        ret.isCurrentlyCapturing = true
        ret.measurements = [MeasurementViewModel(distance: 5.0, id: 1), MeasurementViewModel(distance: 6.0, id: 2), MeasurementViewModel(synchronizationFailed: true, distance: 10.0, id: 4)]

        return ret
    }

    static var previews: some View {
        Group {
            NavigationView {
                MeasurementView(authenticator: MockAuthenticator(username: "test", password: "test", authenticationEndpoint: URL(string: "http://localhost:8080/api/v3/")!))
                    .previewDevice("iPhone 12")
                    .environmentObject(applicationState)
            }

            NavigationView {
                MeasurementView(authenticator: MockAuthenticator(username: "test", password: "test", authenticationEndpoint: URL(string: "http://localhost:8080/api/v3/")!))
                    .previewDevice("iPod touch (7th generation)")
                    .environmentObject(applicationState)
            }

            NavigationView {
                MeasurementView(authenticator: MockAuthenticator(username: "test", password: "test", authenticationEndpoint: URL(string: "http://localhost:8080/api/v3/")!))
                    .preferredColorScheme(.dark)
                    .environmentObject(applicationState)
            }
        }
    }
}

//#if DEBUG
class MockAuthenticator: CredentialsAuthenticator {
    var username: String?

    var password: String?

    var authenticationEndpoint: URL

    init(username: String, password: String, authenticationEndpoint: URL) {
        self.username = username
        self.password = password
        self.authenticationEndpoint = authenticationEndpoint
    }

    func authenticate(onSuccess: @escaping (String) -> Void, onFailure: @escaping (Error) -> Void) {
        onSuccess("test")
    }
}
//#endif
