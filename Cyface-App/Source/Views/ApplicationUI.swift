//
//  ApplicationUI.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 20.06.22.
//

import SwiftUI

struct ApplicationUI: View {

    @EnvironmentObject var appState: ApplicationState

    var body: some View {
        if(!appState.hasAcceptedCurrentPrivacyPolicy) {
            VStack {
                PrivacyPolicyView(settings: appState.settings)
                Button("Accept") {
                    appState.acceptPrivacyPolicy()
                }
            }
        } else if(!appState.hasValidServerURL) {
            ServerURLInputView(initialURL: appState.settings.serverUrl ?? "")
        } else if(!appState.isLoggedIn) {
            let username = appState.settings.username ?? ""
            let password = appState.settings.password ?? ""
            let credentials = Credentials(username: username, password: password)
            LoginView(credentials: credentials)
        } else {
            MeasurementListView()
        }
    }
}

struct ApplicationUI_Previews: PreviewProvider {
    static var previews: some View {
        ApplicationUI().environmentObject(ApplicationState(settings: PreviewSettings()))
    }
}
