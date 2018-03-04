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
 - Version: 1.0.0
 - Since: 1.0.0
 */
public enum DataCapturingEvent {
    /// Occurs everytime the `DataCapturingService` received a geo location fix and thus is able to track its position.
    case geoLocationFixAcquired
    /// Occurs everytime the `DataCapturingService` loses its geo location fix.
    case geoLocationFixLost
    /**
     Occurs each time the `DataCapturingService` receives a new geo location position.
     - position: The new geo location position.
     */
    case geoLocationAcquired(position: GeoLocationMO)
    /**
     Occurs each time the application runs out of space.
     How much space is used and how much is available may be retrieved from `allocation`.
     - allocation: Information about the applications disk (or rather SD card) space consumption.
     */
    case lowDiskSpace(allocation: DiskConsumption)
    /**
     Occurs if the `DataCapturingService` has synchronized all pending cached data successfully
     and deleted the local copies.
     */
    case synchronizationSuccessful
}
