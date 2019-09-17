/*
 * Copyright 2018 Cyface GmbH
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
 Represents one measurement carried out by the Cyface SDK.

 A measurement is a track of geo locations and associated accelerations.

 - Remark: DO NOT confuse this class with CoreData generated model object `MeasurementMO`. Since the model object is not thread safe you should use an instance of this class if you hand data between processes.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 1.0.0
 */
@available(*, deprecated, message: "Use Int64 for an identifier or MeasurementMO to represent a measurement from the database.")
public class MeasurementEntity {

    // MARK: - Properties

    /// The device wide unique identifier of this measurement.
    public let identifier: Int64

    /// The context of this measurement. This is application specific and might be something like the vehicle used.
    public let measurementContext: Modality

    // MARK: - Initializers

    /**
     Creates a new `MeasurementEntity` initializing all its properties to the provided values

     - Parameters:
     - identifier: The device wide unique identifier of this measurement.
     - context: The context of this measurement. This is application specific and might be something like the vehicle used.
     */
    public init(identifier: Int64, context: Modality) {
        self.identifier = identifier
        self.measurementContext = context
    }
}
