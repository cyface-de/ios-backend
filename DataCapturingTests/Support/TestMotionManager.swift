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

    var timer : DispatchSourceTimer?

    override func startAccelerometerUpdates(to queue: OperationQueue, withHandler handler: @escaping CMAccelerometerHandler) {
        timer = DispatchSource.makeTimerSource(queue: queue.underlyingQueue)
        timer!.setEventHandler  {
            queue.addOperation {
                let acceleration = CMAcceleration(x: 1.0,y: 1.0,z: 1.0)
                let data = FakeAccelerometerData(acceleration: acceleration)
                //data?.acceleration = acceleration
                handler(data,nil)
            }
        }
        timer!.schedule(deadline: .now(), repeating: 0.01)
        timer!.resume()
    }

    override var isAccelerometerAvailable: Bool {
        get {
            return true
        }
    }

    override func stopAccelerometerUpdates() {
        timer?.cancel()
        timer = nil
    }

}

class FakeAccelerometerData : CMAccelerometerData {
    override var acceleration: CMAcceleration {
        get {
            return acc
        }
    }

    let acc: CMAcceleration

    init(acceleration: CMAcceleration) {
        self.acc = acceleration
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }
}
