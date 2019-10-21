//
//  TestMotionManager.swift
//  DataCapturingTests
//
//  Created by Team Cyface on 17.03.19.
//  Copyright © 2019 Cyface GmbH. All rights reserved.
//

import Foundation
import CoreMotion

class TestMotionManager: CMMotionManager {

    var timer: DispatchSourceTimer?
    let bootTime = Date()

    override func startAccelerometerUpdates(to queue: OperationQueue, withHandler handler: @escaping CMAccelerometerHandler) {
        timer = DispatchSource.makeTimerSource(queue: queue.underlyingQueue)
        timer!.setEventHandler {
            queue.addOperation { [weak self] in
                guard let self = self else {
                    return
                }

                let acceleration = CMAcceleration(x: 1.0, y: 1.0, z: 1.0)
                let data = FakeAccelerometerData(timestamp: TimeInterval(self.bootTime.timeIntervalSince(Date())),acceleration: acceleration)
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

class FakeAccelerometerData: CMAccelerometerData {
    override var acceleration: CMAcceleration {
        return acc
    }

    override var timestamp: TimeInterval {
        return internalTimestamp
    }

    let acc: CMAcceleration
    let internalTimestamp: TimeInterval

    init(timestamp: TimeInterval, acceleration: CMAcceleration) {
        self.internalTimestamp = timestamp
        self.acc = acceleration
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }
}
