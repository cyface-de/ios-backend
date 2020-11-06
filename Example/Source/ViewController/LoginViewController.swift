//
//  LoginViewController.swift
//  Cyface-Test
//
//  Created by Team Cyface on 18.12.17.
//  Copyright © 2017 Cyface GmbH. All rights reserved.
//

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
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var errorMessageLabel: UILabel!
    
    // MARK: - Actions
    @IBAction func guestLoginButtonTapped(_ sender: UIButton) {
        print("test")
        if UserDefaults.standard.string(forKey: AppDelegate.serverURLKey)==AppDelegate.defaultServerURL {
            UserDefaults.standard.setValue(AppDelegate.guestUsername, forKey: AppDelegate.usernameKey)
            authenticator.username = AppDelegate.guestUsername
            UserDefaults.standard.setValue(AppDelegate.guestPassword, forKey: AppDelegate.passwordKey)
            authenticator.password = AppDelegate.guestPassword

            login()
        } else {
            show(error: "Guest login only possible on default server!")
        }
    }

    @IBAction func loginButtonTapped(_ sender: UIButton) {
        login()
    }
    
    @IBAction func usernameEditted(_ sender: UITextField) {
        guard let text = sender.text else {
            fatalError("LoginViewController.usernameEditted(\(sender.debugDescription)): Unable to get username text from text field!")
        }
        
        UserDefaults.standard.set(text, forKey: AppDelegate.usernameKey)
        authenticator.username = text
    }
    
    @IBAction func passwordEditted(_ sender: UITextField) {
        guard let text = sender.text else {
            fatalError("LoginViewController.passwordEditted(\(sender.debugDescription)): Unable to get password text from text field!")
        }
        
        UserDefaults.standard.set(text, forKey: AppDelegate.passwordKey)
        authenticator.password = text
    }
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        // Only continue if we have a segue identifier
        guard let id = segue.identifier else {
            fatalError("LoginViewController.prepare(\(segue.debugDescription),\(sender.debugDescription)): Tried to call segue without identifier!")
        }
        
        // Only continue with correct segue identifier
        guard id == "ShowMainViewSegue" else {
            fatalError("LoginViewController.prepare(\(segue.debugDescription),\(sender.debugDescription)): Unknown segue \(id) called!")
        }
    }
    
    // MARK: - Properties

    let alert: UIAlertController = {
        let message = NSLocalizedString("Authenticating...", comment: "")
        let ret = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.gray
        loadingIndicator.startAnimating()
        
        ret.view.addSubview(loadingIndicator)
        
        return ret
    }()
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        usernameTextField.text = UserDefaults.standard.string(forKey: AppDelegate.usernameKey)
        passwordTextField.text = UserDefaults.standard.string(forKey: AppDelegate.passwordKey)
    }

    private func show(error: String) {
        DispatchQueue.main.async {
            self.dismiss(animated: true) {
                self.errorMessageLabel.text =  error
                self.errorMessageLabel.sizeToFit()
            }
        }
    }

    private func login() {
        present(alert, animated: true, completion: nil)
        let authenticator = self.authenticator
        // Run this on a background queue, since it is a possibly long running blocking operation.
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else {
                return
            }

            authenticator.authenticate(onSuccess: {_ in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else {
                        return
                    }

                    self.dismiss(animated: true) {
                        self.performSegue(withIdentifier: "ShowMainViewSegue", sender: self)
                        UserDefaults.standard.set(true, forKey: AppDelegate.isAuthenticatedKey)
                    }
                }}, onFailure: { error in
                    self.show(error: NSLocalizedString("err_auth_failed", comment: "Error shown on Authentication not successful!"))
            })
        }
    }
}
