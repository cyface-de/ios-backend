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
    // TODO: Move to Viewmodel
    @State private var username: String = ""
    // TODO: Move to Viewmodel
    @State private var password: String = ""

    var body: some View {
        NavigationStack {
            VStack {

                Image("RFR-Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()

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
                            .stroke(lineWidth: 2)
                    )
                    .foregroundColor(.gray)

                }.padding()

                NavigationLink(destination: LiveView(viewModel: viewModelExample)) {
                    Text("Login")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding([.trailing, .leading])

                LabelledDivider(label: "or")

                NavigationLink(destination: RegistrationView()) {
                    Text("Register New Account")
                }
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Anmeldung")
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
