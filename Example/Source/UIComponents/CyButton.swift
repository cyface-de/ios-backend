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
A basic button pre styled to follow the Cyface UI guidelines.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 9.0.0
 */
class CyButton: UIButton {

    // MARK: - Initializers
    /// A convenience no-argument initializer.
    convenience init() {
        self.init(frame: CGRect.zero)
    }

    /// Initializes the button with the provided frame.
    override init(frame: CGRect) {
        super.init(frame: frame)
        setProperties()
    }

    /// The initializer required to initialize objects of this class from a serialized state.
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setProperties()
    }

    // MARK: - Methods
    /// Sets all the properties of this object according to the Cyface UI guidelines.
    private func setProperties() {
        setTitleColor(UIColor(named: "Cyface-Dark-Green"), for: .normal)
        backgroundColor = UIColor.white
        titleLabel!.font = UIFont(name: "System", size: 17)
    }
}
