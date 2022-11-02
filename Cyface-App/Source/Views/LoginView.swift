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
 The view displayed to the user to login to a Cyface Server

 - author: Klemens Muthmann
 - version: 1.0.0
 */
struct LoginView: View {
    /// The current application state.
    @EnvironmentObject var appState: ApplicationState
    /// The view model used by this view.
    @StateObject private var credentials: LoginViewModel
    /// If `true` the view shows an error message.
    @State private var showError: Bool
    /// The error message to show if `showError` is `true`.
    @State private var errorMessage: String?

    /**
     Initialize the view from the system settings.
     */
    init(settings: Settings, showError: Bool = false, errorMessage: String? = nil) {
        // According to a talk from WWDC 21 this is considered valid, even though the documentation says otherwise.
        // See: https://swiftui-lab.com/random-lessons/#data-10
        self._credentials = StateObject(wrappedValue: LoginViewModel(settings: settings))
        self.showError = showError
        self.errorMessage = errorMessage
    }

    var body: some View {
        if appState.isLoggedIn {
            MeasurementView(authenticator: credentials.authenticator)
        } else {

            VStack {

                Image("Cyface-Logo")

                VStack {
                    HStack {
                        Image(systemName: "person")
                        TextField("Username", text: $credentials.username)
                            .textFieldStyle(CyfaceTextField())
                    }
                    .padding()
                    .overlay(
                            RoundedRectangle(cornerRadius: 15)
                    .stroke(lineWidth: 2))
                    .foregroundColor(.gray)

                    HStack {
                        Image(systemName: "lock")
                        SecureField("Password", text: $credentials.password)
                            .textFieldStyle(CyfaceTextField())
                    }
                    .padding()
                    .overlay(
                            RoundedRectangle(cornerRadius: 15)
                            .stroke(lineWidth: 2)
                        )
                    .foregroundColor(.gray)

                }.padding()


                AsyncButton(action: {
                    do {
                        try credentials.login(onSuccess: {
                            appState.isLoggedIn = true
                        }, onFailure: { error in
                            showError = true
                            errorMessage = error.localizedDescription
                        })
                    } catch {
                        showError = true
                        errorMessage = error.localizedDescription
                    }
                }) {
                    Text("Login")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding([.trailing, .leading])

                LabelledDivider(label: "or")

                NavigationLink(destination: HCaptchaView(settings: credentials.settings)) {
                    Text("Register New Account")
                }
                .frame(maxWidth: .infinity)
            }
            .navigationBarHidden(true)
            .navigationTitle("Login")
            .alert("Error", isPresented: $showError, actions: {
                // actions
            }, message: {
                Text(errorMessage ?? "")
            })
            .tint(Color("Cyface-Green"))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    private static var settings: Settings {
        let ret = PreviewSettings()
        ret.authenticatedServerUrl = nil
        return ret
    }

    private static var appState: ApplicationState {
        let ret = ApplicationState(settings: settings)
        ret.isLoggedIn = false
        return ret
    }

    static var previews: some View {

        Group {
            NavigationView {
                LoginView(settings: settings).preferredColorScheme(.light).environmentObject(appState)
            }

            NavigationView {
                LoginView(settings: settings).preferredColorScheme(.dark).environmentObject(appState)
            }

            NavigationView {
                LoginView(settings: settings, showError: true, errorMessage: "This is some generic error message!").environmentObject(appState)
            }
        }
    }
}
