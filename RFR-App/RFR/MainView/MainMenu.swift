/*
 * Copyright 2024 Cyface GmbH
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
 The applications main menu provides all the functionality not general required and thus not necessary as its own button on the MainView.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
struct MainMenu: View {
    /// The current login status. This is a wrapper for a simple boolean, making it easier to pass into the environment. If it is false, the login screen is shown again.
    /// Having this here is required to change the value if the user presses on `log out`.
    @EnvironmentObject var loginStatus: LoginStatus
    /// Error variable to show an error if one occurs. This is injected from the parent view and shown there.
    @Binding var error: Error?
    /// The authenticator used for authentication and authorization with some type of login server.
    let authenticator: Authenticator

    var body: some View {
        Menu {
            NavigationLink(destination: {
                ProfileView(authenticator: authenticator)
            }) {
                VStack {
                    Image(systemName: "person")
                    Text("Profil").font(.footnote)
                }
            }
            NavigationLink(destination: {ImpressumView()}) {
                VStack {
                    Image(systemName: "info.circle")
                    Text("Impressum").font(.footnote)
                }
            }
            Button(
                action: {
                    Task {
                        do {
                            try await authenticator.logout()
                            loginStatus.isLoggedIn = false
                        } catch {
                            self.error = error
                        }
                    }
                }) {
                    VStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Abmelden").font(.footnote)
                    }
                }
        } label: {
            Label("info",systemImage: "ellipsis")
                .labelStyle(.titleAndIcon)
        }
    }
}

#Preview {
    @State(initialValue: nil) var error: Error?
    return MainMenu(error: $error, authenticator: StaticAuthenticator()).environmentObject(LoginStatus())
}
