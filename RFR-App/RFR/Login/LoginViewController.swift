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
import UIKit
import AppAuth
import OSLog

import Foundation
import DataCapturing

/**
 A UIKit `UIViewController` presenting the applications login screen.

 Although this is a SwiftUI App, currently the AppAuth framework requires a classical view controller, to show its authentication UI.
 Therefore this is implemented as an `UIViewController`.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
class LoginViewController: UIViewController {
    /// A button shown on this view, to restart authentication if it fails.
    var authenticateButton: UIButton!
    let authenticator: Authenticator
    let delegate: LoginViewControllerDelegate

    /**
     Create a new object of this class, providing the application delegate as the sole parameter.
     */
    init(authenticator: Authenticator, delegate: LoginViewControllerDelegate) {
        //self.appDelegate = appDelegate
        self.authenticator = authenticator
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    /// Unsupported constructor, but required by the UIViewController.
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Method to create the view for this `UIViewController`.
    override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground

        authenticateButton = UIButton(type: .system)
        authenticateButton.setTitle("Anmelden oder Registrieren", for: .normal)
        authenticateButton.accessibilityIdentifier = "de.cyface."
        authenticateButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(authenticateButton)

        authenticateButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        authenticateButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        authenticateButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        authenticateButton.addTarget(self, action: #selector(doAuth), for: .touchUpInside)
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        if let oauthAuthenticator = authenticator as? OAuthAuthenticator {
            oauthAuthenticator.callbackController = self
        }
    }

    @objc func doAuth() {
        Task {
            do {
                _ = try await authenticator.authenticate()
                delegate.onLoggedIn()
            } catch {
                delegate.onError(error: error)
            }
        }
    }
}

/**
 Protocol for an old style delegate for handling events reported by the AppAuth framework during authentication.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
protocol LoginViewControllerDelegate {
    func onLoggedIn()
    func onError(error: Error)
}
