/*
 * Copyright 2019 Cyface GmbH
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
import CoreLocation

/**
 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 1.0.0
 */
public protocol TrackCleaner {

    /**
     Checks whether the provided `location` is valid within this cleaner.

     - Parameter location: The location to check for validity
     */
    func isValid(location: CLLocation) -> Bool
}

/**
 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 4.5.0
 */
public class DefaultTrackCleaner: TrackCleaner {
    /// All geo locations captured while being slower than this value in meters per second are cleaned from the track.
    private static let minimumSpeedInMetersPerSecond = 1.0
    /// All geo locations captured while being faster than this value in meters per second are cleaned from the track.
    private static let maximumSpeedInMetersPerSecond = 100.0
    /// All geo locations with an accuracy worse than this value are cleaned from the track.
    private static let upperAccuracyBound = 20.0

    /// Default no argument constructor made public
    public init() {
        // Nothing to do here.
    }

    public func isValid(location: CLLocation) -> Bool {
        return location.speed > DefaultTrackCleaner.minimumSpeedInMetersPerSecond && location.horizontalAccuracy < DefaultTrackCleaner.upperAccuracyBound && location.speed < DefaultTrackCleaner.maximumSpeedInMetersPerSecond
    }
}
