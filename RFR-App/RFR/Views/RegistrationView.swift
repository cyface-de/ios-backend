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
 View allowing the user to register with the Ready-For-Robots auth server.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
struct RegistrationView: View {
    // TODO: Move the following to a view model
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var repeatedPassword: String = ""
    @State private var registrationSuccessful: Bool = false

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                VStack {
                    HStack {
                        Image(systemName: "person")
                        TextField("Username", text: $username)
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
                        SecureField("Password", text: $password)
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
                        SecureField("Repeat Password", text: $repeatedPassword)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding()
                    .overlay(
                            RoundedRectangle(cornerRadius: 15)
                    .stroke(lineWidth: 2))
                    .foregroundColor(.gray)

                }
                .padding()

                Spacer()

                Button(action: {
                    print("register")
                    registrationSuccessful=true
                }) {
                    Text("Register")
                        .frame(maxWidth: .infinity)

                }
                .padding([.leading, .trailing])
                .buttonStyle(.borderedProminent)
                .disabled(!password.isEmpty && password==repeatedPassword)
            }

            NavigationLink(destination: LoginView(), isActive: $registrationSuccessful) {
                EmptyView()
            }
        }
        .navigationTitle("Konto Registrieren")
    }
}

struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        RegistrationView()
    }
}
