/*
 * Copyright 2021 - 2022 Cyface GmbH
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

import XCTest
import DataCapturing
@testable import Cyface

/**
 Tests if the `ViewController` works as expected.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 10.0.0
 */
class ViewControllerTests: XCTestCase {

    /**
     Tests if receiving a synchronization error causes no unexpected failures.
     */
    func testSynchronizingWithError() throws {
        let oocut = ViewController()
        oocut.synchronizing(measurementIdentifier: 1, status: Status.error(TestError.test))
    }
}

/**
 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 10.0.0
 */
enum TestError: Error {
    case test
}
