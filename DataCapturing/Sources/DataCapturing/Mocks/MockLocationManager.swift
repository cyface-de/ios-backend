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
 A mock implementation of a `LocationManager` used during testing. 

 This implementation of a ``LocationManager`` simulates location updates during testing.
 It sends one static location each second to the provided `locationDelegate`.
 Otherwise the test environment throws errors, since a real `CLLocationManager` is not allowed to be used during tests.

 To get additional information about the individual properties and methods see the official [*CoreLocation* documentation](https://developer.apple.com/documentation/corelocation/cllocationmanager).

 - Author: Klemens Muthmann
 - Version: 1.0.2
 - Since: 4.0.0
 */
class MockLocationManager: LocationManager {
    // MARK: - Properties
    /// The mocked authotization simulated to have been given by the user to this ``LocationManager``.
    var authorizationStatus = CLAuthorizationStatus.authorizedAlways

    /// The most recently retrieved user location.
    var location: CLLocation? = CLLocation(
            latitude: 37.3317,
            longitude: -122.0325086
        )

    /// The delegate listening to updates from this ``LocationManager``.
    var locationDelegate: CLLocationManagerDelegate?
    /// Minimum distance in meters a device needs to move horizontally, before an update is reported.
    var distanceFilter: CLLocationDistance = 10
    /// Never pausing location updates during testing.
    var pausesLocationUpdatesAutomatically = false
    /// Setting background mode to true for testing.
    var allowsBackgroundLocationUpdates = true
    /// A timer used to simulate regular location updates.
    var timer: Timer?

    // MARK: - Methods
    /// Ignore this authorization request. It is not relevant during testing.
    func requestWhenInUseAuthorization() { }
    /// Stand a static `CLLocation` in one second intervals to the `locationDelegate`.
    func startUpdatingLocation() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            self?.locationDelegate?.locationManager!(CLLocationManager(), didUpdateLocations: [CLLocation(latitude: 15.0, longitude: 15.0)])
        }
    }
    /// Stop sending a static location.
    func stopUpdatingLocation() {
        timer?.invalidate()
        timer = nil
    }
    /// Send the authorization change event to the system, to see if the system acts appropriately to such an authorization change.
    /// Of course no real authorization change is carried out, as this is not available during headless testing.
    func requestAlwaysAuthorization() {
        locationDelegate?.locationManager?(CLLocationManager(), didChangeAuthorization: .authorizedAlways)
    }
}
