//
//  RegistrationView.swift
//  RFR
//
//  Created by Klemens Muthmann on 27.01.23.
//

import SwiftUI

struct RegistrationView: View {
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
