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
 An enumeration for all errors caused by capturing data.
 ````
 case isPaused
 case notPaused
 case isRunning
 case notRunning
 case noCurrentMeasurement
 ````

 - Author: Klemens Muthmann
 - Since: 1.2.0
 - Version: 1.1.0
 */
public enum DataCapturingError: Error {
    /// Thrown if the service was paused when it should not have been.
    case isPaused
    /// Thrown if the service was not paused when it should have been.
    case notPaused
    /// Thrown if the service was running when it should not have been.
    case isRunning
    /// Thrown if the service was not running when it should have been.
    case notRunning
    /// For some reason there was no current measurement to write data to or to read information to, during a capturing run. This can already happen during start up, if the current measurement was not created for some reason.
    case noCurrentMeasurement
}
