/*
 * Copyright 2022-2024 Cyface GmbH
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
@testable import DataCapturing

/**
 Tests the differential calculation used for efficient data storage.

 - author: Klemens Muthmann
 - version: 1.0.0
 - Since: 12.0.0
 */
class DiffValueErrorTest: XCTestCase {

    /// Tests that overflows of addition provides the correct information.
    func testDiffValueErrorSumOverflow() {
        let oocut = DiffValueError.sumOverflow(firstSummand: 1, secondSummand: 2)
        XCTAssertEqual(oocut.localizedDescription, "Calculation of 1 + 2 caused an overflow!")
    }

    /// Tests that overflow of differential calculations provides the correct information.
    func testDiffValueErrorDiffOverflow() {
        let oocut = DiffValueError.diffOverflow(minuend: 1, subtrahend: 2)
        XCTAssertEqual(oocut.localizedDescription, "Calculation of 1 - 2 caused an overflow!")
    }
}
