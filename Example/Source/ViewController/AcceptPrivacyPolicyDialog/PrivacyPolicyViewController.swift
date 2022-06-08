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
import WebKit

/**
 A delegate from the view model to the view showing the privacy policy.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 9.0.0
 */
protocol PrivacyPolicyViewDelegate: AnyObject {
    /**
     Show the next view after the privacy policy was accepted.
     This can either be a login view, a view asking for a valid server URL or the main data capturing view.
     */
    func nextView()
}

/**
 The view controller is responsible to show the user the applications privacy policy.
 It should be displayed only for as long as the privacy policy has not been accepted.
 The user can only use the app after accepting the privacy policy.

 This is implemented following the MVVM design pattern.

 Author: Klemens Muthmann
 Version: 1.0.0
 Since: 2.0.0
 */
class PrivacyPolicyViewController: CyViewController, PrivacyPolicyViewDelegate {

    // MARK: - Properties
    /// The views title bar shown at the top.
    var titleBar: UINavigationBar = {
        let bar = CyNavigationBar()
        bar.title = "Privacy Policy"

        return bar
    }()

    /// The view showing the privacy policy.
    var webView: WKWebView = {
        let webView = WKWebView()

        return webView
    }()

    /// The button to press to accept the privacy policy.
    var acceptButton: UIButton = {
        let button = CyButton()
        button.setTitle(NSLocalizedString("Accept", comment: "Title text for the accept button!"), for: .normal)
        button.addTarget(PrivacyPolicyViewController.self, action: #selector(acceptPressed), for: .touchUpInside)

        return button
    }()

    /// The view model corresponding to the MVVM pattern.
    private let viewModel: PrivacyPolicyViewModelDelegate

    // MARK: - Initializers
    /**
     Initializes this `UIViewController` based on the provided `viewModel`.

     - Parameter viewModel: The view model to use for this view controller
     */
    init(_ viewModel: PrivacyPolicyViewModelDelegate) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.view = self
    }

    /**
     DO NOT USE THIS!
     */
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods
    /// Distributes the UI elements on the screen
    override func loadView() {
        super.loadView()
        let stackView = UIStackView(frame: CGRect.zero)

        view.addSubview(titleBar)
        view.addSubview(stackView)
        stackView.addSubview(webView)
        stackView.addSubview(acceptButton)

        let safeArea = view.safeAreaLayoutGuide

        titleBar.translatesAutoresizingMaskIntoConstraints = false
        titleBar.topAnchor.constraint(equalTo: safeArea.topAnchor).isActive = true
        titleBar.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor).isActive = true
        titleBar.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor).isActive = true
        titleBar.bottomAnchor.constraint(equalTo: stackView.topAnchor).isActive = true

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor).isActive = true
        stackView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: titleBar.bottomAnchor).isActive = true

        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: stackView.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: acceptButton.topAnchor).isActive = true
        webView.setContentHuggingPriority(UILayoutPriority.dragThatCanResizeScene, for: .horizontal)
        webView.setContentHuggingPriority(UILayoutPriority.dragThatCanResizeScene, for: .vertical)

        acceptButton.translatesAutoresizingMaskIntoConstraints = false
        acceptButton.leadingAnchor.constraint(equalTo: stackView.leadingAnchor).isActive = true
        acceptButton.trailingAnchor.constraint(equalTo: stackView.trailingAnchor).isActive = true
        acceptButton.bottomAnchor.constraint(equalTo: stackView.bottomAnchor).isActive = true
    }

    /// Displays the privacy policy after the view has loaded.
    override func viewDidLoad() {
        super.viewDidLoad()

        let request = NSURLRequest(url: viewModel.privacyPolicyUrl)
        webView.load(request as URLRequest)
    }

    /// Show the next view after the privacy policy has been accepted.
    func nextView() {
        appDelegate.presentMainUI()
    }

    /// Called if the accept button was pressed.
    @objc func acceptPressed() {
        viewModel.privacyPolicyAccepted()
    }
}
