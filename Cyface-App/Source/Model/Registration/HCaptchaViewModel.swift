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

/// An MVVM view model for the HCaptcha view.
///
/// - author: Klemens Muthmann
/// - version: 1.0.0
/// - since: 4.0.0
class HCaptchaViewModel: ObservableObject {
    /// The HCaptcha token, which can be used for user registration.
    @Published var token = ""
    /// A flag that is `true` if an error occured and thus the ``errorMessage`` should be shown on screen.
    /// If there was no error, this is `false`.
    @Published var showError = false
    /// The error message to show if an error has occured.
    @Published var errorMessage = ""
    /// A flag that becomes `true` if the user was validated against HCaptcha.
    /// This triggers the switch to the next view.
    @Published var isValidated = false
    /// A flag that is set to `true` while the HCaptcha is loading.
    /// Since this can take some time a spinner or progress view is shown during that time.
    @Published var isLoading = false
}
