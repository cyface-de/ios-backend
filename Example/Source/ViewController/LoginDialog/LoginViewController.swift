/*
 * Copyright 2017-2021 Cyface GmbH
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

import UIKit
import DataCapturing
import CoreMotion

/**
 The `UIViewController` used to control the login view.
 
 - Author: Klemens Muthmann
 - Version: 1.0.2
 - Since: 1.0.0
 */
class LoginViewController: UIViewController {

    // MARK: - Outlets
    /// The text field containing the currently entered username.
    @IBOutlet weak var usernameTextField: UITextField!
    /// The text field containing the currently entered password.
    @IBOutlet weak var passwordTextField: UITextField!
    /// A label to show error messages on failed login attempts.
    @IBOutlet weak var errorMessageLabel: UILabel!

    // MARK: - Properties
    /// The model used by this view controller.
    var model: Settings?
    /// An internal convenience unwrapped variant of the model.
    private var _model: Settings {
        guard let model = model else {
            fatalError("LoginViewController was not properly initialized! Model is missing!")
        }

        return model
    }

    // MARK: - Actions
    /**
     Called if the user taps and releases the guest login button with the finger inside the button.

     - Parameter sender: The `UIButton` that was pressed
     */
    @IBAction func guestLoginButtonTapped(_ sender: UIButton) {
        if _model.serverUrl==Settings.defaultServerURL {
            _model.username = Settings.guestUsername
            authenticator.username = Settings.guestUsername
            _model.password = Settings.guestPassword
            authenticator.password = Settings.guestPassword

            login()
        } else {
            show(error: "Guest login only possible on default server!")
        }
    }

    /**
     Called if the user taps and releases the login button with the finger inside the button.

     - Parameter sender: The `UIButton` that was pressed
     */
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        login()
    }

    /**
     Called each time the value inside the username text field was editted.

     - Parameter sender: The editted `UITextField`
     */
    @IBAction func usernameEditted(_ sender: UITextField) {
        guard let text = sender.text else {
            fatalError("LoginViewController.usernameEditted(\(sender.debugDescription)): Unable to get username text from text field!")
        }

        _model.username = text
    }

    /**
     Called each time the value inside the password text field was editted.

     - Parameter sender: The editted `UITextField`
     */
    @IBAction func passwordEditted(_ sender: UITextField) {
        guard let text = sender.text else {
            fatalError("LoginViewController.passwordEditted(\(sender.debugDescription)): Unable to get password text from text field!")
        }

        _model.password = text
    }

    // MARK: - Methods
    /**
     Provides an activity indicator to show to the user while the view is unusable during some background activity.
     In this case background activity will be the communication with the Cyface data collector during login.
     This can take some time depending on the current internet connection quality.

     To end the animation just call `removeFromSuperview()` on the returned `UIActivityIndicatorView`

     To prevent the user from interacting with the UI, set for example `isUserInteractionEnabled` to `false` on the parent view.

     - Returns: A `UIActivityIndicatorView` as a child of and centered on the current view
     */
    private func activityIndicator() -> UIActivityIndicatorView {
        let activityIndicatorView = UIActivityIndicatorView(style: .gray)
        activityIndicatorView.center = view.center
        view.addSubview(activityIndicatorView)
        activityIndicatorView.startAnimating()

        return activityIndicatorView
    }

    /**
     Show an error message on the view.

     - Parameter error: The message to show
     */
    private func show(error: String) {
        self.errorMessageLabel.text =  error
        self.errorMessageLabel.sizeToFit()
    }

    /// A method used to login the user and if successful show the main application ui. If not successful an error message is displayed.
    private func login() {
        let activityIndicator = activityIndicator()
        self.view.isUserInteractionEnabled = false

        guard let serverUrlString = self._model.serverUrl, let serverUrl = URL(string: serverUrlString) else {
            self.present(AskForServerViewController(AskForServerViewModel(self._model)), animated: true)
            return
        }
        // These two need to be called here since they use appDelegate in the background and thus need to run on the main queue.
        let authenticator = self.authenticator
        let serverConnection = self.serverConnection

        // Run this on a background queue, since it is a possibly long running blocking operation.
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else {
                return
            }

            // Reset Cyface SDK to use the new URL
            serverConnection.apiURL = serverUrl
            authenticator.authenticationEndpoint = serverUrl
            authenticator.username = self._model.username
            authenticator.password = self._model.password

            authenticator.authenticate(onSuccess: {_ in
                                        DispatchQueue.main.async { [weak self] in
                                            guard let self = self else {
                                                return
                                            }

                                            self.performSegue(withIdentifier: "ShowMainViewSegue", sender: self)
                                            self._model.authenticatedServerUrl = self._model.serverUrl

                                            activityIndicator.removeFromSuperview()
                                            self.view.isUserInteractionEnabled = true
                                        }}, onFailure: { error in
                                            self.show(error: NSLocalizedString("err_auth_failed",
                                                                               comment: "Error shown on Authentication not successful!"))

                                            activityIndicator.removeFromSuperview()
                                            self.view.isUserInteractionEnabled = true
                                        })
        }
    }

    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()

        usernameTextField.text = _model.username
        passwordTextField.text = _model.password
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        // Only continue if we have a segue identifier
        guard let segueIdentifier = segue.identifier else {
            fatalError("LoginViewController.prepare(\(segue.debugDescription),\(sender.debugDescription)): Tried to call segue without identifier!")
        }

        // Only continue with correct segue identifier
        guard segueIdentifier == "ShowMainViewSegue" else {
            fatalError("LoginViewController.prepare(\(segue.debugDescription),\(sender.debugDescription)): Unknown segue \(segueIdentifier) called!")
        }

        guard let mainNavigationViewController = segue.destination as? UINavigationController else {
            fatalError("Invalid segue to wrong ViewController")
        }

        guard let mainViewController = mainNavigationViewController.topViewController as? ViewController else {
            fatalError()
        }

        mainViewController.settings = _model
    }
}
