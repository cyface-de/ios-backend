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

/**
 A model object for an internationalized privacy policy.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
class PrivacyPolicy {
    // MARK: - Properties
    /// The location, where the privacy policy is stored.
    var value: URL? {
        return Bundle.main.url(forResource: fileResource, withExtension: "html")
    }

    // MARK: - Methods
    /// Retrieves the localized resource name of the privacy policy.
    private var fileResource: String {
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
