//
//  ApplicationUI.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 20.06.22.
//

import SwiftUI
import DataCapturing

struct ApplicationUI: View {

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
