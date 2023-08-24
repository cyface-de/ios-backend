//
//  LoginViewController.swift
//  RFR
//
//  Created by Klemens Muthmann on 21.08.23.
//
import UIKit
import AppAuth
import OSLog

import Foundation
class LoginViewController: UIViewController {
    var authState: OIDAuthState?
    // TODO: read this from config file
    let issuer = "https://auth.cyface.de:8443/realms/rfr"
    let clientId = "ios-app"
    let redirectURI = "de.cyface.app.r4r:/oauth2redirect/"
    let appDelegate: AppDelegate
    var delegate: LoginViewControllerDelegate?
    let log = OSLog(subsystem: "LoginViewController", category: "de.cyface")

    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        print("did load")
        super.viewDidLoad()
        // Do any additional setup after loading the view
        self.authState = OAuthAuthenticator.loadState(OAuthAuthenticator.appAuthStateKey)
        print("Auth state \(self.authState)")
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
    func doAuth() throws {
        print("do auth")
        guard let issuer = URL(string: issuer) else {
            throw RFRError.invalidUrl(url: issuer)
        }

        guard let redirectURI = URL(string: redirectURI) else {
            throw RFRError.invalidUrl(url: redirectURI)
        }

        // Discover endpoints
        OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) { [unowned self] configuration, error in
            guard let config = configuration else {
                os_log(
                    "Error retrieving discovery document: %@.",
                    log: log,
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
                        log: log,
                        type: .error,
                        error?.localizedDescription ?? "DEFAULT_ERROR"
                    )
                }
            }
        }
    }

    func setAuthState(_ authState: OIDAuthState?) {
        self.authState = authState
        OAuthAuthenticator.saveState(authState, OAuthAuthenticator.appAuthStateKey)
    }

}

protocol LoginViewControllerDelegate {
    func onLoggedIn()
    func onError(error: Error)
}
