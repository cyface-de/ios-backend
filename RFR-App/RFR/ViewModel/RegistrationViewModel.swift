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
import Combine

/// The MVVM view model used by the ``RegistrationView``
///
/// - author: Klemens Muthmann
/// - version: 1.0.0
/// - since: 4.0.0
class RegistrationViewModel: ObservableObject {
    private static let passwordValidationExpression = try! Regex("^[a-zA-Z0-9!$%&?+*~#_.,/-]{6,32}$")
    private static let emailValidationExpression = try! Regex("(?:[\\p{L}0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[\\p{L}0-9!#$%\\&'*+/=?\\^_`{|}" + "~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\" + "x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[\\p{L}0-9](?:[a-" + "z0-9-]*[\\p{L}0-9])?\\.)+[\\p{L}0-9](?:[\\p{L}0-9-]*[\\p{L}0-9])?|\\[(?:(?:25[0-5" + "]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-" + "9][0-9]?|[\\p{L}0-9-]*[\\p{L}0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21" + "-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])")
    /// The username entered into the username text field. This value is used to get the username to register the new user at.
    @Published var username: String = "" {
        didSet {
            usernameIsValid = (try? RegistrationViewModel.emailValidationExpression.wholeMatch(in: username)) != nil
            showUsernameError = !usernameIsValid
        }
    }
    /// The password entered into the password secure text field. This value is used as the password for the newly created user.
    @Published var password: String = "" {
        didSet {
            let validation = (try? RegistrationViewModel.passwordValidationExpression.wholeMatch(in: password)) != nil
            passwordIsValid = !password.isEmpty && !repeatedPassword.isEmpty && repeatedPassword==password && validation
            showPasswordError = !validation
        }
    }
    /// The repeated password entered into the repeat password secure text field.
    /// This value is used to check if the password was entered correctly.
    /// This value needs to match the value in the password field, before the registration button is enabled.
    @Published var repeatedPassword: String = "" {
        didSet {
            passwordIsValid = !password.isEmpty && !repeatedPassword.isEmpty && repeatedPassword==password
        }
    }
    /// A flag that becomes `true` if registration has finished successfully. If `true` it causes a switch back to the login view.
    @Published var registrationSuccessful = false
    /// The HCaptcha token, which can be used for user registration.
    @Published var token = ""
    /// The error message to show if an error has occured.
    @Published var error: Error?
    /// A flag that becomes `true` if the user was validated against HCaptcha.
    /// This triggers the switch to the next view.
    @Published var isValidated = false
    /// A flag that is set to `true` while the HCaptcha is loading.
    /// Since this can take some time a spinner or progress view is shown during that time.
    @Published var isLoading = false
    @Published var passwordIsValid = false
    @Published var usernameIsValid = false
    @Published var showPasswordError = false
    @Published var showUsernameError = false

    /// Carry out the registration. This is triggered by a press on the register button.
    func register(url: URL) async {

        let requestURL = url.appendingPathComponent("user")
        let registrationRequest = RegistrationRequest(url: requestURL)

        do {
            try await registrationRequest.request(username: username, password: password, validationToken: token)
            DispatchQueue.main.async {
                self.registrationSuccessful = true
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.error = error
            }
        }
    }
}
