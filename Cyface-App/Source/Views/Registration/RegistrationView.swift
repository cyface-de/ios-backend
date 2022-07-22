//
//  RegistrationViewContainer.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 19.07.22.
//

import SwiftUI

struct RegistrationView: View {

    var settings: Settings
    @StateObject var model: RegistrationViewModel

    init(settings: Settings, validationToken: String) {
        self.settings = settings
        self._model = StateObject(wrappedValue: RegistrationViewModel(validationToken: validationToken)) 
    }

    var body: some View {
        NavigationView {
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
                    .textFieldStyle(CyfaceTextField())
                    }
                    .padding()
                    .overlay(
                            RoundedRectangle(cornerRadius: 15)
                    .stroke(lineWidth: 2))
                    .foregroundColor(.gray)

                    HStack {
                        Image(systemName: "lock")
                        SecureField("Repeat Password", text: $model.repeatedPassword)
                    .textFieldStyle(CyfaceTextField())
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
                    guard let url = settings.registrationURL else {
                        model.showError = true
                        model.errorMessage = "No registration URL provided!"
                        return
                    }

                    guard let parseURL = URL(string: url) else {
                        model.showError = true
                        model.errorMessage = "Registration URL is unparseable!"
                        return
                    }

                    Task {
                        await model.register(url: parseURL)
                    }
                }) {
                    Text("Register")
                        .frame(maxWidth: .infinity)

                }
                .padding([.leading, .trailing])
                .buttonStyle(.borderedProminent)
                .disabled(!model.passwordsAreEqualAndNotEmpty)
            }

            NavigationLink(destination: LoginView(settings: settings), isActive: $model.registrationSuccessful) {
                EmptyView()
            }
        }
        .navigationTitle("Account Registration")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Color("Cyface-Green"))
        .alert("Error", isPresented: $model.showError, actions: {
            // actions
        }, message: {
            Text(model.errorMessage)
        })
    }
}

struct RegistrationViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RegistrationView(settings: PreviewSettings(), validationToken: "mysillytoken")
        }

        NavigationView {
            RegistrationView(settings: PreviewSettings(), validationToken: "mysillytoken")
        }.preferredColorScheme(.dark)
    }
}
