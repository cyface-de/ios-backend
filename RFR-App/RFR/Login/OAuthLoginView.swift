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
    @Binding var error: Error? {
        didSet {
            os_log("Failed to Authenticate. %s", log: OSLog.authorization, type: .debug, error?.localizedDescription ?? "")
        }
    }

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
            DispatchQueue.main.async { [weak self] in
                self?.parent.error = error
            }
        }
    }
}

#if DEBUG
#Preview {
    @State var loggedIn = true
    @State var error: Error? = nil

    return OAuthLoginView(
        authenticator: MockAuthenticator(),
        error: $error
    )
}
#endif
