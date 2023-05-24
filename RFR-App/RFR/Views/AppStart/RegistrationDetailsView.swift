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
                    TextField("E-Mail Adresse", text: $model.username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(lineWidth: 2))
                .foregroundColor(.gray)

                if model.showUsernameError {
                    Text("Bitte geben Sie eine gültige E-Mail Adresse ein")
                        .foregroundColor(.red)
                }

                HStack {
                    Image(systemName: "lock")
                    SecureField("Passwort", text: $model.password)
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
                    SecureField("Passwort wiederholen", text: $model.repeatedPassword)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(lineWidth: 2))
                .foregroundColor(.gray)

                if model.showPasswordError {
                    Text("Bitte geben Sie ein gültiges Passwort ein. ")
                        .foregroundColor(.red)
                }

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
                Text("Registrieren")
                    .frame(maxWidth: .infinity)
                    .foregroundColor(Color("ButtonText"))

            }
            .padding([.leading, .trailing])
            .buttonStyle(.borderedProminent)
            .disabled(!model.passwordIsValid && !model.usernameIsValid)
        }
    }

    func textFieldValidatorEmail(_ string: String) -> Bool {
        if string.count > 100 {
            return false
        }
        let emailFormat = "(?:[\\p{L}0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[\\p{L}0-9!#$%\\&'*+/=?\\^_`{|}" + "~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\" + "x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[\\p{L}0-9](?:[a-" + "z0-9-]*[\\p{L}0-9])?\\.)+[\\p{L}0-9](?:[\\p{L}0-9-]*[\\p{L}0-9])?|\\[(?:(?:25[0-5" + "]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-" + "9][0-9]?|[\\p{L}0-9-]*[\\p{L}0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21" + "-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])"
        //let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: string)
    }

    func textFieldValidatorPassword(_ password: String) -> Bool {
        let passwordIsValid = try! Regex("^[a-zA-Z0-9!$%&?+*~#_.,/-]{6,32}$")
        if (try? passwordIsValid.wholeMatch(in: password)) != nil {
            return true
        } else {
            return false
        }
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
