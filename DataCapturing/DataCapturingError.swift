//
//  DataCapturingError.swift
//  DataCapturing
//
//  Created by Team Cyface on 04.09.18.
//  Copyright © 2018 Cyface GmbH. All rights reserved.
//

import Foundation

/**
 An enumeration for all errors caused by capturing data.
 ````
 case isPaused
 case notPaused
 case isRunning
 case notRunning
 ````

 - Author: Klemens Muthmann
 - Since: 1.2.0
 - Version: 1.0.0
 */
public enum DataCapturingError: Error {
    /// Thrown if the service was paused when it should not have been.
    case isPaused
    /// Thrown if the service was no paused when it should have been.
    case notPaused
    /// Thrown if the service was running when it should not have been.
    case isRunning
    /// Thrown if the service was no running when it should have been.
    case notRunning
}
