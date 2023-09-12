/*
 * Copyright 2023 Cyface GmbH
 *
 * This file is part of the Ready for Robots App.
 *
 * The Ready for Robots App is free software: you can redistribute it and/or modify
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

class VoucherOverviewModel {
    let accumulatedKilometers: Double
    let kilometersToAcquire: Double
    let voucherCount: Int

    init(accumulatedKilometers: Double, kilometersToAcquire: Double, voucherCount: Int) {
        self.accumulatedKilometers = accumulatedKilometers
        self.kilometersToAcquire = kilometersToAcquire
        self.voucherCount = voucherCount
    }

    func accumulatedKilometersLabel() throws -> String {
        guard let formattedAccumulatedKilometers = countFormatter.string(from: accumulatedKilometers as NSNumber) else {
            throw RFRError.formattingFailed(number: accumulatedKilometers as NSNumber)
        }

        return formattedAccumulatedKilometers
    }

    func kilometersToAcquireLabel() throws -> String {
        guard let formattedKilometersToAcquire = countFormatter.string(from: kilometersToAcquire as NSNumber) else {
            throw RFRError.formattingFailed(number: kilometersToAcquire as NSNumber)
        }

        return formattedKilometersToAcquire
    }
}
