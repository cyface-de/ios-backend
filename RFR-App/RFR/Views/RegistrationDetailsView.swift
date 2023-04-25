//
//  RegistrationDetailsView.swift
//  RFR
//
//  Created by Klemens Muthmann on 19.04.23.
//

import SwiftUI

struct RegistrationDetailsView: View {
    /// The view model containing the registration information.
    @ObservedObject var model: RegistrationViewModel
    @Binding var showRegistrationView: Bool

    var body: some View {
        VStack {
            VStack {

                HStack {
                    Image(systemName: "person")
                    TextField("Username", text: $model.username)
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
                    SecureField("Password", text: $model.password)
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
                    SecureField("Repeat Password", text: $model.repeatedPassword)
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

            AsyncButton(action: {
                let url = RFRApp.registrationUrl

                guard let parseURL = URL(string: url) else {
                    model.error = RFRError.invalidUrl(url: url)
                    return
                }

                Task {
                    await model.register(url: parseURL)
                    if model.registrationSuccessful {
                        showRegistrationView = false
                    }

                }
            }) {
                Text("Register")
                    .frame(maxWidth: .infinity)
                    .foregroundColor(Color("ButtonText"))

            }
            .padding([.leading, .trailing])
            .buttonStyle(.borderedProminent)
            .disabled(!model.passwordsAreEqualAndNotEmpty)
        }

        .navigationTitle("Account Registration")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RegistrationDetailsView_Previews: PreviewProvider {
    @State static var showRegistrationView = true

    static var previews: some View {
        RegistrationDetailsView(
            model: RegistrationViewModel(),
            showRegistrationView: $showRegistrationView
        )
    }
}
