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
 The central entry point for the user interface.

 An object of this class is used to decide which view is shown at the start of the application and how to initialize the application.

 - author: Klemens Muthmann
 */
struct ApplicationUI: View {

    /// The initial application state.
    @ObservedObject var appState: ApplicationState

    var body: some View {
        NavigationView {
            // Show splash screen as long as CoreData etc. loads
            if(appState.isInitialized) {
                // Show privacy policy until accepted
                if(!appState.hasAcceptedCurrentPrivacyPolicy) {
                    VStack {
                        PrivacyPolicyView(settings: appState.settings)
                        Button(action:  {
                            appState.acceptPrivacyPolicy()
                        }) {
                            Text("Accept")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .tint(Color("Cyface-Green"))
                    .navigationTitle("Privacy Policy")
                    .navigationBarBackButtonHidden(true)
                // Ask for a valid Server URL if non has been provided
                } else if(!appState.hasValidServerURL) {
                    ServerURLInputView(initialURL: appState.settings.serverUrl ?? "")
                // Enable login
                } else {
                    LoginView(settings: appState.settings)
                }
            } else {
                SplashScreen()
            }
        }
        .tint(Color("Cyface-Green"))
    }
}

struct ApplicationUI_Previews: PreviewProvider {
    private static var settings = PreviewSettings()

    static var previews: some View {
        ApplicationUI(appState: ApplicationState(settings: settings))
    }
}
