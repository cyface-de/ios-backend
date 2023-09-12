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

struct OAuthLoginView: UIViewControllerRepresentable {
    let appDelegate: AppDelegate
    @Binding var loggedIn: Bool
    @Binding var error: Error?

    func makeUIViewController(context: Context) -> LoginViewController {
        // Return the ViewController
        let ret = LoginViewController(appDelegate: appDelegate)
        ret.delegate = context.coordinator
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
                self?.parent.loggedIn = true
            }
        }

        func onError(error: Error) {
            DispatchQueue.main.async { [weak self] in
                self?.parent.error = error
            }
        }
    }
}

struct UIKitViewController_Previews: PreviewProvider {
    @State static var loggedIn: Bool = true
    @State static var error: Error? = nil

    static var previews: some View {
        OAuthLoginView(appDelegate: AppDelegate(), loggedIn: $loggedIn, error: $error)
    }
}
