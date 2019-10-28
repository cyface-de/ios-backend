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
import CoreMotion

/**
 A motion manager that does not require actual sensors and thus runs also while testing.
 Instead of actual sensors this manager creates random values.

 - Author: Klemens Muthmann
 - Version: 1.0.2
 - Since: 2.0.0
 */
class TestMotionManager: CMMotionManager {

    /// Internal timer simulating new sensor values.
    var timer: DispatchSourceTimer?
    /// Using the first call to this class as system boot time (probably not correct).
    let bootTime = Date()

    override func startAccelerometerUpdates(to queue: OperationQueue, withHandler handler: @escaping CMAccelerometerHandler) {
        timer = DispatchSource.makeTimerSource(queue: queue.underlyingQueue)
        timer!.setEventHandler {
            queue.addOperation { [weak self] in
                guard let self = self else {
                    return
                }

                let acceleration = CMAcceleration(x: 1.0, y: 1.0, z: 1.0)
                let data = FakeAccelerometerData(timestamp: TimeInterval(self.bootTime.timeIntervalSince(Date())), acceleration: acceleration)
                //data?.acceleration = acceleration
                handler(data, nil)
            }
        }
        timer!.schedule(deadline: .now(), repeating: 0.01)
        timer!.resume()
    }

    override var isAccelerometerAvailable: Bool {
        return true
    }

    override func stopAccelerometerUpdates() {
        timer?.cancel()
        timer = nil
    }

}

/**
 Accelerometer data with fake values.
 This allows the creation of tests on sensor capturing.

 - Author: Klemens Muthmann
 - Version: 1.0.1
 - Since: 2.0.0
 */
class FakeAccelerometerData: CMAccelerometerData {
    override var acceleration: CMAcceleration {
        return acc
    }

    override var timestamp: TimeInterval {
        return internalTimestamp
    }

    /// The simulated acceleration data.
    let acc: CMAcceleration
    /// The simulated time stamp of the capturing.
    let internalTimestamp: TimeInterval

    /**
     Creates a new `FakeAccelerometerData` with all values properly initialized.

     - Parameters:
        - timestamp: The simulated time stamp of the capturing.
        - acceleration: The simulated acceleration data.
     */
    init(timestamp: TimeInterval, acceleration: CMAcceleration) {
        self.internalTimestamp = timestamp
        self.acc = acceleration
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }
}
