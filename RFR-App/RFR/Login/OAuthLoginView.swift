//
//  OAuthLoginView.swift
//  RFR
//
//  Created by Klemens Muthmann on 21.08.23.
//

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
