/*
 * Copyright 2022 Cyface GmbH
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
 Errors thrown during the calculation of differential values for serialization.

 - author: Klemens Muthmann
 - version: 1.0.0
 */
enum DiffValueError: Error {
    case int32DiffOverflow(minuend: Int32, subtrahend: Int32)
    case int64DiffOverflow(minuend: UInt64, subtrahend: UInt64)
    case int32SumOverflow(firstSummand: Int32, secondSummand: Int32)
    case int64SumOverflow(firstSummand: UInt64, secondSummand: UInt64)
}

extension DiffValueError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .int32DiffOverflow(minuend: let minuend, subtrahend: let subtrahend):
            let errorMessage =  NSLocalizedString(
                "de.cyface.error.DiffValueError.int32DiffOverflow",
                value: "Calculation of %d - %d caused a signed 32 bit integer overflow!",
                comment: """
Tell the user that there was an overflow while calculating the differential value for serialization! \
The minuend and subtrahend of the calculation are provided as the first and second argument.
""")
            return String.localizedStringWithFormat(errorMessage, minuend, subtrahend)

        case .int64DiffOverflow(minuend: let minuend, subtrahend: let subtrahend):
            let errorMessage =  NSLocalizedString(
                "de.cyface.error.DiffValueError.int64DiffOverflow",
                value: "Calculation of %d - %d caused an unsigned 64-bit integer overflow!",
                comment: """
Tell the user that there was an overflow while calculating the differential value for serialization! \
The minuend and subtrahend of the calculation are provided as the first and second argument.
""")
            return String.localizedStringWithFormat(errorMessage, minuend, subtrahend)

        case .int32SumOverflow(firstSummand: let firstSummand, secondSummand: let secondSummand):
            let errorMessage =  NSLocalizedString(
                "de.cyface.error.DiffValueError.int32SumOverflow",
                value: "Calculation of %d + %d caused an Int32 overflow!",
                comment: """
Tell the user that there was an overflow while resolving the differential value for deserialization! \
The first and second summand of the calculation are provided as the first and second argument.
""")
            return String.localizedStringWithFormat(errorMessage, firstSummand, secondSummand)

        case .int64SumOverflow(firstSummand: let firstSummand, secondSummand: let secondSummand):
            let errorMessage =  NSLocalizedString(
                "de.cyface.error.DiffValueError.int64SumOverflow",
                value: "Calculation of %d + %d caused an unsigned 64-bit integer overflow!",
                comment: """
Tell the user that there was an overflow while resolving the differential value for deserialization! \
The first and second summand of the calculation are provided as the first and second argument.
""")
            return String.localizedStringWithFormat(errorMessage, firstSummand, secondSummand)
        }
    }
}
