/*
 * Copyright 2023 Cyface GmbH
 *
 * This file is part of the Read-for-Robots iOS App.
 *
 * The Read-for-Robots iOS App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Read-for-Robots iOS App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Read-for-Robots iOS App. If not, see <http://www.gnu.org/licenses/>.
 */

import SwiftUI

/**
 View asking for user credentials and handling the login to the Ready-For-Robots Server.
 */
struct LoginView: View {
    @ObservedObject var viewModel: LoginViewModel
    @State var showRegistrationView = false

    var body: some View {
        // This cannot be inside a navigation view since HCaptcha does not work inside NavigationStack elements.
        if showRegistrationView {
            RegistrationView(
                model: RegistrationViewModel(),
                showRegistrationView: $showRegistrationView
            )
        } else if let error = viewModel.error {
            ErrorView(error: error)
        } else {
            VStack {
                Image("RFR-Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()

                CredentialsView(credentials: viewModel.credentials)
                
                AsyncButton(action: {
                    Task {
                        await viewModel.onLoginButtonClicked()
                    }
                }) {
                    Text("Login")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(Color("ButtonText"))
                    
                }
                .buttonStyle(.borderedProminent)
                .padding([.trailing, .leading])
                
                LabelledDivider(label: "or")

                Button(action: {
                    showRegistrationView = true
                }
                ) {
                    Text("Register New Account")
                }
                .frame(maxWidth: .infinity)
                .padding([.trailing, .leading, .bottom])
            }
        }
    }
}

#if DEBUG
struct LoginView_Previews: PreviewProvider {
    @State static var isAuthenticated = false
    static var previews: some View {
        LoginView(
            viewModel: LoginViewModel(
                credentials: Credentials(username: "testusers", password: "12345"),
                error: nil,
                authenticator: MockAuthenticator()
            )
        )
    }
}
#endif
