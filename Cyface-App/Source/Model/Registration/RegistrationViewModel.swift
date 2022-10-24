/*
 * Copyright 2022 Cyface GmbH
 *
 * This file is part of the Cyface SDK for iOS.
 *
 * The Cyface SDK for iOS is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Cyface SDK for iOS is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Cyface SDK for iOS. If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation

/// The MVVM view model used by the ``RegistrationView``
///
/// - author: Klemens Muthmann
/// - version: 1.0.0
/// - since: 4.0.0
class RegistrationViewModel: ObservableObject {
    /// The username entered into the username text field. This value is used to get the username to register the new user at.
    @Published var username: String = ""
    /// The password entered into the password secure text field. This value is used as the password for the newly created user.
    @Published var password: String = "" {
        didSet {
            passwordsAreEqualAndNotEmpty = !password.isEmpty && !repeatedPassword.isEmpty && repeatedPassword==password
        }
    }
    /// The repeated password entered into the repeat password secure text field.
    /// This value is used to check if the password was entered correctly.
    /// This value needs to match the value in the password field, before the registration button is enabled.
    @Published var repeatedPassword: String = "" {
        didSet {
            passwordsAreEqualAndNotEmpty = !password.isEmpty && !repeatedPassword.isEmpty && repeatedPassword==password
        }
    }
    /// A flag that is `true` if both ``password`` and ``repeatedPassword`` contain the same non empty value.
    @Published var passwordsAreEqualAndNotEmpty = false
    /// A valid HCaptcha token required to prove to the registration server, that this is a human and no automated bot.
    @Published var challengeToken: String
    /// A flag that is `true` if there was an error and triggers the system to show an error message. If there was no error it is `false`.
    @Published var showError: Bool = false
    /// The error message to show if any. This message is shown if ``showError`` is `true`.
    @Published var errorMessage: String = ""
    /// A flag that becomes `true` if registration has finished successfully. If `true` it causes a switch back to the login view.
    @Published var registrationSuccessful = false

    /// Create a new view model with a proper HCaptcha `validationToken`, proving that the registration is issued by a human.
    init(validationToken: String) {
        self.challengeToken = validationToken
    }

    /// Carry out the registration. This is triggered by a press on the register button.
    func register(url: URL) async {

        let requestURL = url.appendingPathComponent("user")
        let registrationRequest = RegistrationRequest(url: requestURL)

        do {
            try await registrationRequest.request(username: username, password: password, validationToken: challengeToken)
            self.registrationSuccessful = true
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.showError = true
                self?.errorMessage = error.localizedDescription
            }
        }
    }
}
