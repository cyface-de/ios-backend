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
 A `UINavigationBar` following the Cyface UI guidelines.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 9.0.0
 */
class CyNavigationBar: UINavigationBar {

    // MARK: - Properties
    /// The title property for the navigation bar. This must be the key to a localized string and will be decoded using `NSLocalizedString`.
    var title: String? {
        get {
            return self.topItem?.title
        }

        set(value) {
            guard let value = value else {
                return
            }

            let navigationItem = UINavigationItem(title: NSLocalizedString(value, comment: "The title of the navigation bar!"))
            self.setItems([navigationItem], animated: false)
        }
    }

    // MARK: - Initializers
    /// Initializes a new `CyNavigationBar` within the provided frame. Just use `CGRect.zero` if you do not know the frame yet.
    override init(frame: CGRect) {
        super.init(frame: frame)
        setProperties()
    }

    /// Initializes a `CyNavigationBar` from a serialized form.
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setProperties()
    }

    // MARK: - Methods
    /// Sets the navigation bars properties appropriately.
    private func setProperties() {
        backgroundColor = UIColor(named: "Cyface-Dark-Green")
        barTintColor = UIColor(named: "Cyface-Dark-Green")
        tintColor = UIColor.white // for titles, buttons, etc.
        let navigationTitleFont = UIFont.systemFont(ofSize: 17.0)
        titleTextAttributes = [NSAttributedString.Key.font: navigationTitleFont, NSAttributedString.Key.foregroundColor: UIColor.white]
    }
}
