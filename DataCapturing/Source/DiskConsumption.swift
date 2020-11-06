/*
 * Copyright 2017 Cyface GmbH
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
 Objects of this class represent the current disk (or rather SD card) space used and available.
 
 - Author: Klemens Muthmann
 - Version: 1.0.0
  - Since: 1.0.0
 
 This space is mostly filled with unsynchronized `Measurement`s.
 To avoid filling up the users SD card it is advisable to delte `Measurement`s as soon as they use up too much space.
 */
public class DiskConsumption {

    // MARK: - Properties

    /**
     The amount of bytes currently used by the `DataCapturingService`.
     */
    public let consumedBytes: Int
    /**
     The amount of bytes still available for the `DataCapturingService`.
     */
    public let availableBytes: Int

    // MARK: - Initializers

    /**
     Creates a new completely initialized `DiskConsumption` object.
     
     - Parameters:
        - consumedBytes: The amount of bytes currently used by the `DataCapturingService`.
        - availableBytes: The amount of bytes still available for the `DataCapturingService`.
     */
    public init(consumedBytes: Int, availableBytes: Int) {
        guard consumedBytes>=0 else {
            fatalError("Illegal value for consumed bytes. May not be smaller then 0 but was \(consumedBytes)")
        }
        guard availableBytes>=0 else {
            fatalError("Illegal value for available bytes. May not be smaller then 0 but was \(availableBytes)")
        }

        self.consumedBytes = consumedBytes
        self.availableBytes = availableBytes
    }
}
