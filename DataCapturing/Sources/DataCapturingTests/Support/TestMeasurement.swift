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
import Combine
import OSLog
@testable import DataCapturing

/**
 A `DataCapturingService` using mocked sensors to run, during tests.

 - Author: Klemens Muthmann
 - Version: 2.0.0
 - Since: 4.0.0
 */
class TestMeasurement: DataCapturing.Measurement {
    var measurementMessages = PassthroughSubject<DataCapturing.Message, Never>()

    var isRunning: Bool = false

    var isPaused: Bool = false

    /// The timer used to simulate location updates every second, like in the real app.
    var timer: DispatchSourceTimer?
    var altitudeTimer: DispatchSourceTimer?

    func start() throws {
        timer = DispatchSource.makeTimerSource()
        altitudeTimer = DispatchSource.makeTimerSource()

        timer?.setEventHandler { [weak self] in
            let location = TestFixture.randomLocation()
            self?.measurementMessages.send(Message.capturedLocation(location))
        }
        altitudeTimer?.setEventHandler { [weak self] in
            let altitude = TestFixture.randomAltitude()
            self?.measurementMessages.send(Message.capturedAltitude(altitude))
        }

        timer?.schedule(deadline: .now(), repeating: 1)
        altitudeTimer?.schedule(deadline: .now(), repeating: 0.5)
        isRunning = true
        isPaused = false
        self.measurementMessages.send(Message.started(timestamp: Date()))
        timer?.resume()
        altitudeTimer?.resume()
    }

    func stop() throws {
        timer?.cancel()
        altitudeTimer?.cancel()
        timer = nil
        altitudeTimer = nil
        isRunning = false
        isPaused = false
        os_log("Sending stop event", log: OSLog.test, type: .debug)
        self.measurementMessages.send(Message.stopped(timestamp: Date()))
        self.measurementMessages.send(completion: .finished)
    }

    func pause() throws {
        timer?.suspend()
        altitudeTimer?.suspend()
        isPaused = true
        isRunning = false
        self.measurementMessages.send(Message.paused(timestamp: Date()))
        self.measurementMessages.send(completion: .finished)
    }

    func resume() throws {
        timer?.resume()
        altitudeTimer?.resume()
        isPaused = false
        isRunning = true
        self.measurementMessages.send(Message.resumed(timestamp: Date()))
    }

    func changeModality(to modality: String) {
        self.measurementMessages.send(Message.modalityChanged(to: modality))
    }
}
