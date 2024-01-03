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
 * The Ready for Robots App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Ready for Robots App. If not, see <http://www.gnu.org/licenses/>.
 */
import Foundation

/**
The view model used by the view shown before a voucher has been acquired.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.2
 */
class VoucherOverviewModel {
    // MARK: - Properties
    /// The number of already accumulated kilometers towards acquiring a voucher
    let accumulatedKilometers: Double
    /// The number of kilometers to acquire before getting the opportunity to aqcuire a voucher.
    let kilometersToAcquire: Double
    /// The count of still available vouchers.
    let voucherCount: Int

    // MARK: - Initializers
    /// Create a new object with this class setting its complete initial state.
    init(accumulatedKilometers: Double, kilometersToAcquire: Double, voucherCount: Int) {
        self.accumulatedKilometers = accumulatedKilometers
        self.kilometersToAcquire = kilometersToAcquire
        self.voucherCount = voucherCount
    }

    // MARK: - Methods
    /// Transform the number of accumulated kilometers to a correctly localized text representation.
    /// - Throws: If the number was not convertible, which should not happen under normal circumstances.
    func accumulatedKilometersLabel() throws -> String {
        guard let formattedAccumulatedKilometers = countFormatter.string(from: accumulatedKilometers as NSNumber) else {
            throw RFRError.formattingFailed(number: accumulatedKilometers as NSNumber)
        }

        return formattedAccumulatedKilometers
    }

    /// Transform the number of kilometers to acquire into a correctly localized text representation.
    /// - Throws If the number was not convertible, which should not happen under normal circumstances.
    func kilometersToAcquireLabel() throws -> String {
        guard let formattedKilometersToAcquire = countFormatter.string(from: kilometersToAcquire as NSNumber) else {
            throw RFRError.formattingFailed(number: kilometersToAcquire as NSNumber)
        }

        return formattedKilometersToAcquire
    }
}
