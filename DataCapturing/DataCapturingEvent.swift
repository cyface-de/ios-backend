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
 Events occuring during capturing and transmitting data.
 
 These events may be received by a closure provided to the `DataCapturingService` on calling start.
 
 - Author: Klemens Muthmann
 - Version: 2.0.0
 - Since: 1.0.0
 */
public enum DataCapturingEvent {
    /// Occurs everytime the `DataCapturingService` received a geo location fix and thus is able to track its position.
    case geoLocationFixAcquired
    /// Occurs everytime the `DataCapturingService` loses its geo location fix.
    case geoLocationFixLost
    /**
     Occurs each time the `DataCapturingService` receives a new geo location position.

     - Parameter position: The new geo location position.
     */
    case geoLocationAcquired(position: GeoLocation)
    /**
     Occurs each time the application runs out of space.
     How much space is used and how much is available may be retrieved from `allocation`.

     - Parameter allocation: Information about the applications disk (or rather SD card) space consumption.
     */
    case lowDiskSpace(allocation: DiskConsumption)
    /**
     Used to notify the client application of a successful start of the `DataCapturingService`.
     */
    case serviceStarted(measurement: MeasurementEntity)
    /**
     Occurs if the `DataCapturingService` has synchronized a measurement successfully
     and cleaned the local copies.

     - Parameter measurement: The measurement which finished synchronization.
     - Parameter status: Whether synchronization was a success or a failure.
     */
    case synchronizationFinished(measurement: MeasurementEntity, status: Status)
    /**
     Occurs when the synchronization of a measurement has started.

     - Parameter measurement: The measurement the gets synchronized.
     */
    case synchronizationStarted(measurement: MeasurementEntity)
}
