//
//  DataCapturingEvents.swift
//  DataCapturing
//
//  Created by Team Cyface on 13.12.17.
//  Copyright © 2017 Cyface GmbH. All rights reserved.
//

import Foundation

/**
 Events occuring during capturing and transmitting data.
 
 These events may be received by a closure provided to the `DataCapturingService` on calling start.
 
 - Author: Klemens Muthmann
 - Version: 1.1.0
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
     Occurs if the `DataCapturingService` has synchronized a measurement successfully
     and cleaned the local copies.

     - Parameter measurement: The measurement which finished synchronization.
     - Parameter status: Whether synchronization was a success or a failure.
     */
    case synchronizationFinished(measurement: MeasurementEntity, status: SynchronizationStatus)
    /**
     Occurs when the synchronization of a measurement has started.

     - Parameter measurement: The measurement the gets synchronized.
    */
    case synchronizationStarted(measurement: MeasurementEntity)
    /**
     Used to notify the client application of a successful start of the `DataCapturingService`.
     */
    case serviceStarted(measurement: MeasurementEntity)
}

/**
 Provides information on whether a synchronization was successful or not.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 2.0.0
 */
public enum SynchronizationStatus {
    /**
    Data synchronization complete succefully.
    */
    case success
    /**
     Data synchronization failed.s
    */
    case failure
}
