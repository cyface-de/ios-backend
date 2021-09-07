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

import Foundation

// MARK: - PrivacyPolicyViewModelDelegate
/**
 Delegate protocal for `PrivacyPolicyViewModel` instances.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
protocol PrivacyPolicyViewModelDelegate: AnyObject {
    // MARK: - Properties
    /// The localized resource privacy policy as a resource.
    var privacyPolicyUrl: URL { get }
    /// The current version of the privacy policy. This can be compared to the currently accepted version to decide on whether to show a dialog to ask for acceptance.
    var currentPrivacyPolicyVersion: Int { get }
    /// The view this view model handels.
    var view: PrivacyPolicyViewDelegate? { get set }
    // MARK: - Methods
    /// Called when the privacy policy is accepted
    func privacyPolicyAccepted()
}

// MARK: - PrivacyPolicyViewModel
/**
 View model backing a view that show the current privacy policy and asks for acceptance.
 For further details lock up the MVVM design pattern.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
class PrivacyPolicyViewModel: PrivacyPolicyViewModelDelegate {
    // MARK: - Properties
    /// The model handled by this view model.
    let model: Settings
    /// The view this view model notifies about relevant model changes.
    weak var view: PrivacyPolicyViewDelegate?

    /// The URL to the current privacy policy.
    let privacyPolicyUrl: URL = {
        let localization = Bundle.main.preferredLocalizations.first
        switch localization {
        case "de":
            return loadPrivacyPolicy("privacy-policy-de")
        case "it":
            return loadPrivacyPolicy("privacy-policy-it")
        default:
            return loadPrivacyPolicy("privacy-policy-en")
        }
    }()

    /// The current version of the privacy policy.
    let currentPrivacyPolicyVersion: Int

    // MARK: - Initializers
    /**


     - Parameter model: The model to store data to and read data from.
     This is currently a reference to the system settings, which stores the last accepted privacy policy version.
     - Parameter currentPrivacyPolicyVersion: The current version of the privacy policy that should be accepted.
     */
    init(_ model: Settings, _ currentPrivacyPolicyVersion: Int) {
        self.model = model
        self.currentPrivacyPolicyVersion = currentPrivacyPolicyVersion
    }

    // MARK: - Methods
    /**
     Return the location of a privacy policy file as a URL.

     - Parameter fileName: The name of the privacy policy file (without file extension).
     */
    private static func loadPrivacyPolicy(_ fileName: String) -> URL {
        guard let ret = Bundle.main.url(forResource: fileName, withExtension: "html") else {
            fatalError("Unable to load privacy policy!")
        }

        return ret
    }

    /**
     Called when the user accepted the privacy policy.
     */
    func privacyPolicyAccepted() {
        model.highestAcceptedPrivacyPolicy = currentPrivacyPolicyVersion
        view?.nextView()
    }
}
