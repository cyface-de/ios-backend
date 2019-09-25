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
 - Version: 1.1.0
 - Since: 2.2.0
 */
public protocol DistanceCalculationStrategy {
    /**
     Calculate the distance in meters between the provided `CLLocation` instances.

     - Parameters:
        - from: The location to start the distance calculation from
        - to: The location to calculate the distance to
     */
    func calculateDistance(from previousLocation: CLLocation, to location: CLLocation) -> Double

    /**
     This is similar to `calculateDistance(:CLLocation,:CLLocation)` but accepts `GeoLocationMO` arguments.

     - Parameters:
        - from: The location to start the distance calculation from
        - to: The location to calculate the distance to
     */
    func calculateDistance(from previousLocation: GeoLocationMO, to location: GeoLocationMO) -> Double

    /**
     Calculate the distance between two coordinate pairs

     - Parameters:
        - from: The source coordinate pair, where the first element is the latitude and the second is longitude
        - to: The target coordinate pair, where the first element is the latitude and the second is longitude
     */
    func calculateDistance(from previousLocationLatLonCoordinates: (Double, Double), to locationLatLonCoordinates: (Double, Double)) -> Double
}

// MARK: - Implementation
/**
 Calculates the distance between two locations based on the internal distance function provided by iOS.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 2.2.0
 */
public class DefaultDistanceCalculationStrategy: DistanceCalculationStrategy {

    // MARK: - Initializers

    /// A no-argument default consturctor.
    public init() {
        // Nothing to do here.
    }

    // MARK: - Methods

    public func calculateDistance(from previousLocation: CLLocation, to location: CLLocation) -> Double {
        return location.distance(from: previousLocation)
    }

    public func calculateDistance(from previousLocation: GeoLocationMO, to location: GeoLocationMO) -> Double {
        let previousCLLocation = CLLocation(latitude: previousLocation.lat, longitude: previousLocation.lon)
        let clLocation = CLLocation(latitude: location.lat, longitude: location.lon)
        return calculateDistance(from: previousCLLocation, to: clLocation)
    }

    public func calculateDistance(from previousLocationLatLonCoordinates: (Double, Double), to locationLatLonCoordinates: (Double, Double)) -> Double {
        return calculateDistance(from: CLLocation(latitude: previousLocationLatLonCoordinates.0, longitude: previousLocationLatLonCoordinates.1), to: CLLocation(latitude: locationLatLonCoordinates.0, longitude: locationLatLonCoordinates.1))
    }
}
