/*
 * Copyright 2017-2022 Cyface GmbH
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

// TODO: Remove this!
/**
 Events occuring during capturing and transmitting data.
 
 These events may be received by a closure provided to the `DataCapturingService` on calling start.
 ```
 case geoLocationFixAcquired
 case geoLocationFixLost
 case geoLocationAcquired
 case lowDiskSpace
 case serviceStarted
 case servicePaused
 case serviceResumed
 case serviceStopped
 case synchronizationFinished
 case synchronizationStarted
 ```
 
 - Author: Klemens Muthmann
 - Version: 4.0.0
 - Since: 1.0.0
 */
public enum DataCapturingEvent: CustomStringConvertible {
    /// Occurs everytime the `DataCapturingService` received a geo location fix and thus is able to track its position.
    case geoLocationFixAcquired
    /// Occurs everytime the `DataCapturingService` loses its geo location fix.
    case geoLocationFixLost
    /**
     Occurs each time the `DataCapturingService` receives a new geo location position.

     - position: The new geo location position.
     */
    case geoLocationAcquired(position: LocationCacheEntry)
    /**
     Occurs each time the application runs out of space.
     How much space is used and how much is available may be retrieved from `allocation`.

     - allocation: Information about the applications disk (or rather SD card) space consumption.
     */
    case lowDiskSpace(allocation: DiskConsumption)
    /**
     Used to notify the client application of a successful start of the `DataCapturingService`.

     - measurement: The device wide unique identifier of the measurement for which the service has started
     - event: The event stored for this service start
     */
    case serviceStarted(measurement: UInt64?, event: Event)
    /**
     Used to notify the client application of a successful pause of the `DataCapturingService`.

     - measurement: The device wide unique identifier of the measurement for which the service has paused
     - event: The event stored for this service pause
     */
    case servicePaused(measurement: UInt64?, event: Event)
    /**
     Used to notify the client application of a successful resume of the `DataCapturingService`.

     - measurement: The device wide unique identifier of the measurement for which the service has resumed
     - event: The event stored for this service resume
    */
    case serviceResumed(measurement: UInt64?, event: Event)
    /**
     Used to notify the client application of a successful stop of the `DataCapturingService`.

     - measurement: The device wide unique identifier of the measurement for which the service has stopped
     - event: The event stored for this service stop
     */
    case serviceStopped(measurement: UInt64?, event: Event)
    /**
     Occurs if the `DataCapturingService` has finished synchronizing a measurement.
     This does not necessarily mean, that the synchronization was successful.
     Please check with the local data storage using a `PersistenceLayer` to see if the measurement synchronization was successful or not.

     - measurement: The measurement which finished synchronization.
     */
    case synchronizationFinished(measurement: FinishedMeasurement)
    /**
     Occurs when the synchronization of a measurement has started.

     - measurement: The measurement the gets synchronized.
     */
    case synchronizationStarted(measurement: FinishedMeasurement)

    /// A stringyfied variant of this object, mostly used for human readable representation during debugging sessions.
    public var description: String {
        switch self {
        case .geoLocationFixAcquired: return "geoLocationFixAcquired"
        case .geoLocationFixLost: return "geoLocationFixLost"
        case .geoLocationAcquired(let location): return "geoLocationAcquired(\(location))"
        case .lowDiskSpace(let allocation): return "lowDiskSpace(\(allocation))"
        case .serviceStarted(let measurementIdentifier, let event): return "serviceStarted(\(String(describing: measurementIdentifier)), \(event))"
        case .servicePaused(let measurementIdentifier, let event): return "servicePaused(\(String(describing: measurementIdentifier)), \(event))"
        case .serviceResumed(let measurementIdentifier, let event): return "serviceResumed(\(String(describing: measurementIdentifier)), \(event))"
        case .serviceStopped(let measurementIdentifier, let event): return "serviceStopped(\(String(describing: measurementIdentifier)), \(event))"
        case .synchronizationFinished(let measurement): return "synchronizationFinished(\(measurement.identifier))"
        case .synchronizationStarted(let measurement): return "synchronizationStarted(\(measurement.identifier))"
        }
    }
}
