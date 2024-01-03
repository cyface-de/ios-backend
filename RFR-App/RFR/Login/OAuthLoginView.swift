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
 * The Ready for Robots App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Reay for Robots App. If not, see <http://www.gnu.org/licenses/>.
 */

import SwiftUI
import DataCapturing
import OSLog

/**
 The interface used to embed AppAuth into this SwiftUI application.

 Since the AppAuth framework does not support SwiftUI yet, we need to use the UIKit adapter to integrate AppAuth with the *Ready for Robots* App.
 The UIKit view controller handled by this adapter is the ``LoginViewController``.
 It passes control back to this application via the delegate pattern realized by the embedded ``Coordinator``.

 - SeeAlso: ``LoginViewController``
 - SeeAlso: ``OAuthAuthenticator``
 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.2
 */
struct OAuthLoginView {
    // MARK: - Properties
    let authenticator: Authenticator
    /// The applications login status from the environment.
    /// Setting this to `true` tells the application that the user has been logged in an the main view should be displayed.
    @EnvironmentObject var loginStatus: LoginStatus
    /// Stores all the errors occuring during the login process. This enables us to show multiple errors if necessary.
    @Binding var errors: [String]

    /**
     The delegate called from the ``LoginViewController`` on all events relevant for the SwiftUI application.

     - Author: Klemens Muthmann
     - Version: 1.0.0
     - Since: 3.1.2
     */
    class Coordinator: LoginViewControllerDelegate {
        // MARK: - Properties
        /// A reference to the parent so we are able to set the login state and communicate errors to other parts of the user interface.
        var parent: OAuthLoginView

        // MARK: - Initializers
        /// Create a new instance with a connection to the parent ``OAuthLoginView``
        init(_ parent: OAuthLoginView) {
            self.parent = parent
        }

        // MARK: - Methods
        /// Handle a successful login.
        func onLoggedIn() {
            DispatchQueue.main.async { [weak self] in
                self?.parent.loginStatus.isLoggedIn = true
            }
        }

        /// Handle any error thrown during the login process.
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

extension OAuthLoginView: UIViewControllerRepresentable {
    // MARK: - Methods
    /// Create the adapted view controller and connect it to the delegate and the authenticator.
    func makeUIViewController(context: Context) -> LoginViewController {
        // Return the ViewController
        let ret = LoginViewController(authenticator: authenticator, delegate: context.coordinator)
        return ret
    }

    /// Not required by this implementation but must be provided by the `UIViewControllerRepresentable` protocol.
    func updateUIViewController(_ uiViewController: LoginViewController, context: Context) {
        // Do nothing for now
    }

    /// Create the delegate receiving events from the adapted ``LoginViewController``
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
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
