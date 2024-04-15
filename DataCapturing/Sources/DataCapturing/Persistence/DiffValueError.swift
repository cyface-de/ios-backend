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

import Foundation

/**
 Errors thrown during the calculation of differential values for serialization.

 - author: Klemens Muthmann
 - version: 1.0.0
 - Since: 12.0.0
 */
enum DiffValueError<T: FixedWidthInteger>: Error {
    /// Thrown on a number overflow during a subraction.
    case diffOverflow(minuend: T, subtrahend: T)
    /// Thrown on a number overflow during an addition.
    case sumOverflow(firstSummand: T, secondSummand: T)
}

extension DiffValueError: LocalizedError {
    /// The localized error description for `DiffValueError` instances.
    public var errorDescription: String? {
        switch self {
        case .diffOverflow(minuend: let minuend, subtrahend: let subtrahend):
            let errorMessage = NSLocalizedString("de.cyface.error.DiffValueError.diffOverflow",
                                                 value: "Calculation of %@ - %@ caused an overflow!",
                                                 comment: """
                Tell the user that there was an overflow while calculating the differential value for serialization!\
                The minuend and subtrahend of the calculation are provided as the first and second argument.
                """)
            return String.localizedStringWithFormat(errorMessage, minuend.description, subtrahend.description)
        case .sumOverflow(firstSummand: let firstSummand, secondSummand: let secondSummand):
            let errorMessage = NSLocalizedString("de.cyface.error.DiffValueError.sumOverflow",
                                                 value: "Calculation of %@ + %@ caused an overflow!",
                                                 comment: """
                Tell the user that there was an overflow while resolving the summed value for deserialization! \
                The first and second summand of the calculation are provided as the first and second argument.
                """)
            return String.localizedStringWithFormat(errorMessage, firstSummand.description, secondSummand.description)
        }
    }
}
