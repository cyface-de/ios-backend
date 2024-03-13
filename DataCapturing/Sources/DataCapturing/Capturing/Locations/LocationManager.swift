/*
 * Copyright 2019-2024 Cyface GmbH
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
 Protocol which enables us to provide mock location managers to unit tests.
 This only implements the methods required by the `DataCapturingService`, since we need to only mock those away.

 The idea behind this is described in detail for example here: https://rwhtechnology.com/blog/unit-test-cllocationmanager-with-mock/

 - Author: Klemens Muthmann
 - Version: 1.1.1
 - Since: 4.0.0
 */
public protocol LocationManager {
    // MARK: - Properties
    /// A wrapper for the delegate receiving the location updates.
    var locationDelegate: CLLocationManagerDelegate? { get set }
    /// The current authorization given by the user of the implementing application.
    var authorizationStatus: CLAuthorizationStatus { get }

    // MARK: - Methods
    /// Starts listening for location updates and delivering new update to the delegate.
    func startUpdatingLocation()
    /// Stops location updates. No further updates are delivered to the delegate after this point.
    func stopUpdatingLocation()
    /// Ask the user to provide authorization to capture locations in the foreground and in the background.
    func requestAlwaysAuthorization()
}

// MARK: - Implementation of LocationManager
extension CLLocationManager: LocationManager {
    /// A wrapper for the delegate used by *CoreLocation*.
    public var locationDelegate: CLLocationManagerDelegate? {
        get {
            return self.delegate
        }
        set {
            self.delegate = newValue
        }
    }
}
