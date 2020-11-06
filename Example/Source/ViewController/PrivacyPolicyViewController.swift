//
//  PrivacyPolicyViewController.swift
//  Cyface
//
//  Created by Team Cyface on 27.09.19.
//  Copyright © 2019 Cyface GmbH. All rights reserved.
//

import UIKit
import WebKit

/**
 The view controller is responsible to show the user the applications privacy policy. It should be displayed only once as long as the privacy policy has not been accepted. The user can only use the app after accepting the privacy policy.

 Author: Klemens Muthmann
 Version: 1.0.0
 Since: 2.0.0
 */
class PrivacyPolicyViewController: UIViewController {

    // MARK: - Outlets
    /// The view showing the privacy policy
    @IBOutlet weak var webView: WKWebView!

    // MARK: - Properties
    /// Tells the system which is the current version of the privacy policy. This is important to reshow the privacy policy if there happens to be an update to the text.
    public static let currentPrivacyPolicyVersion = 1

    // MARK: - UIViewController
    /// Displays the privacy policy after the view has loaded.
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let fileResource = getFileResource()
        if let filePath = Bundle.main.url(forResource: fileResource, withExtension: "html") {
            let request = NSURLRequest(url: filePath)
            webView.load(request as URLRequest)
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        UserDefaults.standard.set(PrivacyPolicyViewController.currentPrivacyPolicyVersion, forKey: AppDelegate.highestAcceptedPrivacyPolicyKey)
    }

    // MARK: Methods

    /// Retrieves the localized resource name of the privacy policy.
    private func getFileResource() -> String {
        let localization = Bundle.main.preferredLocalizations.first
        if localization == "de" {
            return "privacy-policy-de"
        } else if localization == "it" {
            return "privacy-policy-it"
        } else {
            return "privacy-policy-en"
        }
    }

}
