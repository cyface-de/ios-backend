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
    @State private var showPassword = false
    @Binding var isAuthenticated: Bool

    var body: some View {
            VStack {
                Image("RFR-Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
                
                VStack {
                    HStack {
                        Image(systemName: "person")
                        TextField("Username", text: $viewModel.username)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(lineWidth: 2))
                    .foregroundColor(.gray)
                    
                    HStack {
                        Image(systemName: "lock")
                        if showPassword {
                            TextField(
                                "Password",
                                text: $viewModel.password
                            )
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .frame(height: 10)
                        } else {
                            SecureField("Password", text: $viewModel.password)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .frame(height: 10)
                        }

                        Button(action: {showPassword.toggle()}) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                        }
                    }
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(lineWidth: 2)
                    )
                    .foregroundColor(.gray)
                    
                }.padding()
                
                AsyncButton(action: {
                    Task {
                        if await viewModel.authenticate() != nil {
                            isAuthenticated = true
                        }
                    }
                }) {
                    Text("Login")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(Color("ButtonText"))
                    
                }
                .buttonStyle(.borderedProminent)
                .padding([.trailing, .leading])

                LabelledDivider(label: "or")
                
                NavigationLink(destination: RegistrationView()) {
                    Text("Register New Account")
                }
                .frame(maxWidth: .infinity)
                .padding([.trailing, .leading, .bottom])
            }
        .alert(viewModel.error?.localizedDescription.description ?? "No Error Information available", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        }
    }
}

#if DEBUG
struct LoginView_Previews: PreviewProvider {
    @State static var isAuthenticated = false
    static var previews: some View {
        LoginView(
            viewModel: LoginViewModel(
                username: "testusers",
                password: "12345",
                showError: false,
                error: nil,
                authenticator: MockAuthenticator()
            ),
            isAuthenticated: $isAuthenticated
        )
    }
}
#endif
