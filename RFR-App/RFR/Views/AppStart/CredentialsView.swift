//
//  CredentialsView.swift
//  RFR
//
//  Created by Klemens Muthmann on 22.05.23.
//

import SwiftUI

struct CredentialsView: View {
    @ObservedObject var credentials: Credentials
    @State private var showPassword = false

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "person")
                TextField("Username", text: $credentials.username)
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
                        text: $credentials.password
                    )
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .frame(height: 10)
                } else {
                    SecureField("Password", text: $credentials.password)
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
    }
}

struct CredentialsView_Previews: PreviewProvider {
    static var previews: some View {
        CredentialsView(
            credentials: Credentials(
                username: "TestUser",
                password: "TestPassword"
            )
        )
    }
}
