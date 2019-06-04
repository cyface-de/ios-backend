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
        timer!.setEventHandler { [weak self] in
            guard let self = self else {
                return
            }

            let location = self.generateLocation()
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

    private func generateLocation() -> CLLocation {
        return CLLocation(coordinate: CLLocationCoordinate2D(latitude: Double.random(in: -90.0...90.0), longitude: Double.random(in: -180.0...180.0)), altitude: Double.random(in: 0.0...8848.0), horizontalAccuracy: Double.random(in: 0.0...20.0), verticalAccuracy: Double.random(in: 0.0...20.0), course: Double.random(in: 0.0...1.0), speed: Double.random(in: 0.0...80.0), timestamp: Date())
    }
}
