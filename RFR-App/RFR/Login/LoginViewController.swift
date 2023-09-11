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

/**
 A UIKit `UIViewController` presenting the applications login screen.

 Although this is a SwiftUI App, currently the AppAuth framework requires a classical view controller, to show its authentication UI.
 Therefore this is implemented as an `UIViewController`.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
class LoginViewController: UIViewController {
    /// The AppAuth frameworks object storing the authentication state of the user using this application.
    var authState: OIDAuthState?
    // TODO: read this from config file
    /// The address for the identity provider, that issues authentication tokens.
    let issuer = "https://auth.cyface.de:8443/realms/rfr"
    //let issuer = "http://localhost:8081/realms/rfr"
    /// The identifier of this client as required by the identity provider.
    let clientId = "ios-app"
    /// The local redirect URI the identity provider is supposed to call after authentication has been finished.
    let redirectURI = "de.cyface.app.r4r:/oauth2redirect/"
    /// The application, which is required to store and load the authentication state of this application.
    let appDelegate: AppDelegate
    /// An old style delegate used to handle events, that might occur during authentication and need to be handled by the app.
    var delegate: LoginViewControllerDelegate?
    /// A button shown on this view, to restart authentication if it fails.
    var authenticateButton: UIButton!

    /**
     Create a new object of this class, providing the application delegate as the sole parameter.
     */
    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
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
        authenticateButton.setTitle("Anmelden", for: .normal)
        authenticateButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(authenticateButton)

        authenticateButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        authenticateButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        authenticateButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        authenticateButton.addTarget(self, action: #selector(doAuth), for: .touchUpInside)
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view
        self.authState = OAuthAuthenticator.loadState(OAuthAuthenticator.appAuthStateKey)
        if let authState = self.authState, authState.isAuthorized {
            delegate?.onLoggedIn()
        } else {
            do {
                try doAuth()
            } catch {
                delegate?.onError(error: error)
            }
        }
    }

    // TODO: Move this to the Authenticator
    /// Starts the authentication process.
    @objc func doAuth() throws {
        guard let issuer = URL(string: issuer) else {
            throw RFRError.invalidUrl(url: issuer)
        }

        guard let redirectURI = URL(string: redirectURI) else {
            throw RFRError.invalidUrl(url: redirectURI)
        }

        // Discover endpoints
        OIDAuthorizationService.discoverConfiguration(forIssuer: issuer, completion: { [unowned self] configuration, error in
            guard let config = configuration else {
                os_log(
                    "Error retrieving discovery document: %@.",
                    log: OSLog.authorization,
                    type: .error,
                    error?.localizedDescription ?? "DEFAULT_ERROR"
                )
                return
            }

            // Build Authentication Request
            let request = OIDAuthorizationRequest(
                configuration: config,
                clientId: self.clientId,
                clientSecret: nil,
                scopes: [OIDScopeOpenID, OIDScopeProfile],
                redirectURL: redirectURI,
                responseType: OIDResponseTypeCode,
                additionalParameters: nil
            )
            self.appDelegate.currentAuthorizationFlow = OIDAuthState.authState(
                byPresenting: request,
                presenting: self
            ) { [weak self] authState, error in
                guard let self = self else {
                    return
                }

                if let authState = authState {
                    self.setAuthState(authState)

                    delegate?.onLoggedIn()
                } else {
                    os_log(
                        "Authorization error: %@",
                        log: OSLog.authorization,
                        type: .error,
                        error?.localizedDescription ?? "DEFAULT_ERROR"
                    )
                }
            }
        })
    }

    /// Set and save the current authentication state.
    func setAuthState(_ authState: OIDAuthState?) {
        self.authState = authState
        OAuthAuthenticator.saveState(authState, OAuthAuthenticator.appAuthStateKey)
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
