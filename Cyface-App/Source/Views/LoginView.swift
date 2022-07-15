//
//  ContentView.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 25.03.22.
//

import SwiftUI
import DataCapturing

struct LoginView: View {

    @EnvironmentObject var appState: ApplicationState
    @StateObject private var credentials: Credentials
    @State private var loginSuccessful = false
    @State private var showError: Bool
    @State private var errorMessage: String?

    init(settings: Settings, showError: Bool = false, errorMessage: String? = nil) {
        // According to a talk from WWDC 21 this is considered valid, even though the documentation says otherwise.
        // See: https://swiftui-lab.com/random-lessons/#data-10
        self._credentials = StateObject(wrappedValue: Credentials(settings: settings))
        self.showError = showError
        self.errorMessage = errorMessage
    }

    var body: some View {
        if credentials.authenticator != nil {
            MeasurementView(authenticator: credentials.authenticator)
        } else {

            VStack {

                Image("Cyface-Logo")

                VStack {
                    CyfaceTextField(label: "Username", binding: $credentials.username)
                        .disableAutocorrection(true)
                    SecureField("Password", text: $credentials.password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }.padding()


                Button("Login") {
                    do {
                        try credentials.login(onSuccess: {
                            loginSuccessful = true
                        },
                                              onFailure: { error in
                            showError = true
                            errorMessage = error.localizedDescription
                        })
                    } catch {
                        showError = true
                        errorMessage = error.localizedDescription
                    }
                }
                .buttonStyle(CyfaceButton())
                .frame(maxWidth: .infinity)


                Text("or").padding()

                Button("Register New Account") {

                }
                .buttonStyle(CyfaceButton())
                .frame(maxWidth: .infinity)
            }
            .navigationBarHidden(true)
            .navigationTitle("Login")
            .alert("Error", isPresented: $showError, actions: {
                // actions
            }, message: {
                Text(errorMessage ?? "")
            })
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    private static var settings: Settings {
        let ret = PreviewSettings()
        ret.authenticatedServerUrl = nil
        return ret
    }

    static var previews: some View {

        Group {
            NavigationView {
                LoginView(settings: settings).preferredColorScheme(.light).environmentObject(ApplicationState(settings: settings))
            }

            NavigationView {
                LoginView(settings: settings).preferredColorScheme(.dark).environmentObject(ApplicationState(settings: settings))
            }

            NavigationView {
                LoginView(settings: settings, showError: true, errorMessage: "This is some generic error message!").environmentObject(ApplicationState(settings: settings))
            }
        }
    }
}
