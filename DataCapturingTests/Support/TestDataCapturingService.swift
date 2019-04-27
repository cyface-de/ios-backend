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
@testable import DataCapturing

/**
 A `DataCapturingService` using mocked sensors to run, during tests.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 4.0.0
 */
class TestDataCapturingService: DataCapturingService {

    /// The timer used to simulate location updates every second, like in the real app.
    var timer: DispatchSourceTimer?

    override func startCapturing(savingEvery time: TimeInterval) throws {
        try super.startCapturing(savingEvery: time)
        timer = DispatchSource.makeTimerSource()
        timer!.setEventHandler {
            let location = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 10.0, longitude: 10.0), altitude: 10.0, horizontalAccuracy: 10.0, verticalAccuracy: 10.0, course: 1.0, speed: 2.0, timestamp: Date())
            self.locationManager(CLLocationManager(), didUpdateLocations: [location])
        }
        timer!.schedule(deadline: .now(), repeating: 1)
        timer!.resume()
    }

    override func stopCapturing() {
        super.stopCapturing()
        timer?.cancel()
        timer = nil
    }
}
