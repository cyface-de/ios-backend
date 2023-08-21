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
class PrivacyPolicy: ObservableObject {
    // MARK: - Properties
    private static let acceptedVersionKey = "de.cyface.rfr.privacypolicyversion"
    @Published var mostRecentWasAccepted: Bool

    /// The URL to the current privacy policy.
    let url: URL = {
        let localization = Bundle.main.preferredLocalizations.first
        switch localization {
        case "de":
            return load(from: "privacy-policy-de")
        default:
            return load(from: "privacy-policy-en")
        }
    }()

    /// The current version of the privacy policy.
    static let currentVersion = 2

    init() {
        mostRecentWasAccepted = PrivacyPolicy.highestAcceptedVersion() >= PrivacyPolicy.currentVersion
    }

    // MARK: - Methods
    /**
     Return the location of a privacy policy file as a URL.

     - Parameter fileName: The name of the privacy policy file (without file extension).
     */
    private static func load(from fileName: String) -> URL {
        guard let ret = Bundle.main.url(forResource: fileName, withExtension: "html") else {
            fatalError("Unable to load privacy policy!")
        }

        return ret
    }

    /**
     Called when the user accepted the privacy policy.
     */
    func onAccepted() {
        UserDefaults.standard.setValue(PrivacyPolicy.currentVersion, forKey: PrivacyPolicy.acceptedVersionKey)
        UserDefaults.standard.synchronize()
        self.mostRecentWasAccepted = PrivacyPolicy.highestAcceptedVersion() >= PrivacyPolicy.currentVersion
    }

    private static func highestAcceptedVersion() -> Int {
        return UserDefaults.standard.integer(forKey: PrivacyPolicy.acceptedVersionKey)
    }
}
