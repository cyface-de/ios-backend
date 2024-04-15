/*
 * Copyright 2024 Cyface GmbH
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
import XCTest
@testable import DataCapturing

extension XCTestCase {
    public static func testBundle() -> Bundle? {
        return Bundle.module
    }

    public static func appBundle() -> Bundle? {
        let mainBundle = Bundle(for: CoreDataStack.self)
        let appBundle = Bundle(url: mainBundle.bundleURL.appendingPathComponent("DataCapturing_DataCapturing.bundle"))
        return appBundle
    }
}
