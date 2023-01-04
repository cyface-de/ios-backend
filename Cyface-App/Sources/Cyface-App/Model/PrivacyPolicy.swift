/*
 * Copyright 2021-2022 Cyface GmbH
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

/**
 View model backing a view that show the current privacy policy and asks for acceptance.
 For further details lock up the MVVM design pattern.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 1.0.0
 */
class PrivacyPolicy {
    // MARK: - Properties
    /// The model handled by this view model.
    let model: Settings

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
    static let currentPrivacyPolicyVersion = 2

    // MARK: - Initializers
    /**
     - Parameter model: The model to store data to and read data from.
     This is currently a reference to the system settings, which stores the last accepted privacy policy version.
     */
    init(_ model: Settings) {
        self.model = model
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
        model.highestAcceptedPrivacyPolicy = PrivacyPolicy.currentPrivacyPolicyVersion
    }
}
