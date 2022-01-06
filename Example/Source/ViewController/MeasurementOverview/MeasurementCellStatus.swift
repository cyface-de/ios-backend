/*
 * Copyright 2018 - 2022 Cyface GmbH
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
 An enumeration for all the possible status variants a measurement can be in.

 - Author: Klemens Muthmann
 - Since: 3.1.0
 - Version 1.1.0
 */
enum MeasurementCellStatus: CustomStringConvertible {
    /// The measurement is not synchronized yet and was not tried.
    case unsynchronized
    /// The measurement is currently synchronizing with the Cyface server.
    case uploading
    /// The measurement upload has failed previously.
    case uploadFailed
    /// The measurement was successfully synchronized.
    case uploadSuccessful

    public var description: String {
        switch self {
        case .unsynchronized:
            return ".unsychronized"
        case .uploading:
            return ".uploading"
        case .uploadFailed:
            return ".uploadFailed"
        case .uploadSuccessful:
            return ".uploadSuccessful"
        }
    }
}
