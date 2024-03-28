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

public extension Double {
    /// Compare two double values observing floating point precision
    func equal(_ value: Double, precise: Int) -> Bool {
        let denominator: Double = pow(10.0, Double(precise))
        let maxDiff: Double = 1 / denominator
        let realDiff: Double = self - value

        if fabs(realDiff) <= maxDiff {
            return true
        } else {
            return false
        }
    }
}
