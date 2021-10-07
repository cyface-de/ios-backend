/*
 * Copyright 2021 Cyface GmbH
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

/**
 A `UIViewController` that is shown if the current server address is not valid.
 Currently we check whether it is a valid URL but not if it actually points to a Cyface data collector.
 If it does not, the user will simply not be able to authenticate.
 
 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 9.0.0
 */
class AskForServerViewController: CyViewController {

    // MARK: - Properties
    /// The text field containing the new Cyface collector service URL entered by the user
    let serverAddressTextField: UITextField = {
        let textfield = UITextField()
        textfield.font = UIFont(name: "System", size: 17)
        textfield.borderStyle = UITextField.BorderStyle.roundedRect
        textfield.placeholder = NSLocalizedString("Server Address", comment: "Shown to ask the user for a server address to upload captured data to.")
        textfield.autocorrectionType = .no
        textfield.autocapitalizationType = .none

        return textfield
    }()

    /// A button to confirm the user input.
    let okButton: UIButton = {
        let button = CyButton()
        button.setTitle(NSLocalizedString("okAction", comment: "Shown to acknowledge an alert dialog!"), for: .normal)

        button.addTarget(self, action: #selector(okClicked), for: .touchUpInside)

        return button
    }()

    /// The title bar at the top of the screen showing a header text.
    let titleBar: UINavigationBar = {
        let bar = CyNavigationBar()
        bar.title = "Upload Server Address"

        return bar
    }()

    /// A label showing error messages if a URL was not accepted.
    let errorLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.textColor = UIColor.red

        return label
    }()

    /// The view model to back data, data validation and business logic of this view.
    let viewModel: AskForServerViewModelDelegate

    // MARK: - Initializers
    /**
     Initialize a new object of this view based on the provided `viewModel`.

     - Parameter viewModel: The view model to back data, data validation and business logic of this view
     */
    init(_ viewModel: AskForServerViewModelDelegate) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    /// DO NOT USE THIS!
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods
    /// Called when the OK button is clicked
    @objc
    func okClicked() {
        let serverAddressTextFieldContent = serverAddressTextField.text
        do {
            try viewModel.change(serverAddress: serverAddressTextFieldContent)
        } catch {
            show(error: "\(NSLocalizedString("invalidUrlError", comment: "The error message shown to the user!"))")
        }
    }

    /**
     Show an error message on the view.

     - Parameter error: The message to show
     */
    private func show(error: String) {
        self.errorLabel.text =  error
        self.errorLabel.sizeToFit()
    }

    // MARK: - CyViewController
    override func loadView() {
        super.loadView()
        let safeZone = view.safeAreaLayoutGuide

        view.addSubview(titleBar)

        view.addSubview(serverAddressTextField)
        view.addSubview(errorLabel)
        view.addSubview(okButton)

        titleBar.translatesAutoresizingMaskIntoConstraints = false
        titleBar.topAnchor.constraint(equalTo: safeZone.topAnchor).isActive = true
        titleBar.leadingAnchor.constraint(equalTo: safeZone.leadingAnchor).isActive = true
        titleBar.trailingAnchor.constraint(equalTo: safeZone.trailingAnchor).isActive = true

        serverAddressTextField.translatesAutoresizingMaskIntoConstraints = false
        serverAddressTextField.topAnchor.constraint(equalTo: safeZone.centerYAnchor).isActive = true
        serverAddressTextField.leadingAnchor.constraint(equalTo: safeZone.leadingAnchor).isActive = true
        serverAddressTextField.trailingAnchor.constraint(equalTo: safeZone.trailingAnchor).isActive = true
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.topAnchor.constraint(equalTo: serverAddressTextField.bottomAnchor, constant: 10.0).isActive = true
        errorLabel.leadingAnchor.constraint(greaterThanOrEqualTo: safeZone.leadingAnchor, constant: 10.0).isActive = true
        errorLabel.trailingAnchor.constraint(lessThanOrEqualTo: safeZone.trailingAnchor, constant: 10.0).isActive = true
        errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        okButton.translatesAutoresizingMaskIntoConstraints = false
        okButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        okButton.widthAnchor.constraint(equalTo: serverAddressTextField.widthAnchor).isActive = true
        okButton.bottomAnchor.constraint(equalTo: safeZone.bottomAnchor).isActive = true
    }
}
