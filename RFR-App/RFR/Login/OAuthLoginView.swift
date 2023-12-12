/*
 * Copyright 2023 Cyface GmbH
 *
 * This file is part of the Ready for Robots App.
 *
 * The Ready for Robots App is free software: you can redistribute it and/or modify
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
import SwiftUI
import DataCapturing
import OSLog

struct OAuthLoginView: UIViewControllerRepresentable {
    let authenticator: Authenticator
    @EnvironmentObject var loginStatus: LoginStatus
    @Binding var errors: [String]

    func makeUIViewController(context: Context) -> LoginViewController {
        // Return the ViewController
        let ret = LoginViewController(authenticator: authenticator, delegate: context.coordinator)
        return ret
    }

    func updateUIViewController(_ uiViewController: LoginViewController, context: Context) {
        // Do nothing for now
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: LoginViewControllerDelegate {
        var parent: OAuthLoginView

        init(_ parent: OAuthLoginView) {
            self.parent = parent
        }

        func onLoggedIn() {
            DispatchQueue.main.async { [weak self] in
                self?.parent.loginStatus.isLoggedIn = true
            }
        }

        func onError(error: Error) {
            os_log("Failed to Authenticate. %@", log: OSLog.authorization, type: .error, error.localizedDescription)

            DispatchQueue.main.async { [weak self] in
                if case OAuthAuthenticatorError.missingAuthState = error {
                    os_log("Ignoring missing auth state and showing login form again!", log: OSLog.authorization, type: .debug)
                } else {
                    self?.parent.errors.append(error.localizedDescription)
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    @State var loggedIn = true
    @State var errors: [String] = []

    return OAuthLoginView(
        authenticator: MockAuthenticator(),
        errors: $errors
    )
}
#endif
