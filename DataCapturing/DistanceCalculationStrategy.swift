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
 This protocol provides a way to calculate the distance between two geo locations in meters.
 Different implementations are possible.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 2.2.0
 */
protocol DistanceCalculationStrategy {
    /**
     Calculate the distance in meters between the provided `CLLocation` instances.

     - Parameters:
     - from: The location to start the distance calculation from
     - to: The location to calculate the distance to
     */
    func calculateDistance(from previousLocation: CLLocation, to location: CLLocation) -> Double
}

/**
 Calculates the distance between two locations based on the internal distance function provided by iOS.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 2.2.0
 */
class DefaultDistanceCalculationStrategy: DistanceCalculationStrategy {
    func calculateDistance(from previousLocation: CLLocation, to location: CLLocation) -> Double {
        return location.distance(from: previousLocation)
    }
}
