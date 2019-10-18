//
//  SensorCapturer.swift
//  DataCapturing
//
//  Created by Team Cyface on 17.10.19.
//  Copyright © 2019 Cyface GmbH. All rights reserved.
//

import Foundation
import CoreMotion
import os.log

/**
 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 5.1.0
 */
class SensorCapturer {

    private static let log = OSLog(subsystem: "de.cyface", category: "SensorCapturer")

    /// An in memory storage for accelerations, before they are written to disk.
    var accelerations = [SensorValue]()
    var rotations = [SensorValue]()
    var directions = [SensorValue]()
    private let lifecycleQueue: DispatchQueue
    private let capturingQueue: DispatchQueue
    /// An instance of `CMMotionManager`. There should be only one instance of this type in your application.
    private let motionManager: CMMotionManager
    var isEmpty: Bool {
        return accelerations.isEmpty && rotations.isEmpty && directions.isEmpty
    }

    init(lifecycleQueue: DispatchQueue, capturingQueue: DispatchQueue, motionManager: CMMotionManager) {
        self.lifecycleQueue = lifecycleQueue
        self.capturingQueue = capturingQueue
        self.motionManager = motionManager
    }

    func start() {
        let queue = OperationQueue()
        queue.qualityOfService = QualityOfService.userInitiated
        queue.underlyingQueue = capturingQueue
        if motionManager.isAccelerometerAvailable {
            motionManager.startAccelerometerUpdates(to: queue, withHandler: handle)
        }

        if motionManager.isGyroAvailable {
            motionManager.startGyroUpdates(to: queue, withHandler: handle)
        }

        if motionManager.isMagnetometerAvailable {
            motionManager.startMagnetometerUpdates(to: queue, withHandler: handle)
        }
    }

    func stop() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        motionManager.stopMagnetometerUpdates()
    }

    /**
        The handler provided to *CoreMotion* for handling new accelerations.

        See `CMAccelerometerHandler` in the Apple documentation for futher information.

     - Parameters:
        - data: The new accelerometer data in any is available or `nil` otherwise.
        - error: An error or `nil` if no error occured.
     */
    private func handle(_ data: CMAccelerometerData?, _ error: Error?) {
        if let error = error as? CMError {
            os_log("Accelerometer error: %@", log: SensorCapturer.log, type: .error, error.rawValue)
        }

        guard let data = data else {
            // Should only happen if the device accelerometer is broken or something similar. If this leads to problems we can substitute by a soft error handling such as a warning or something similar. However in such a case we might think everything works fine, while it really does not.
            fatalError("No Accelerometer data available!")
        }

        let accValues = data.acceleration
        let timestamp = Date(timeInterval: data.timestamp, since: kernelBootTime())
        let acc = SensorValue(timestamp: timestamp,
                               x: accValues.x,
                               y: accValues.y,
                               z: accValues.z)
        // Synchronize this write operation.
        self.lifecycleQueue.async(flags: .barrier) {
            self.accelerations.append(acc)
        }
    }

    private func handle(_ data: CMGyroData?, _ error: Error?) {
        if let error = error as? CMError {
            os_log("Gyroscope error: %@", log: SensorCapturer.log, type: .error, error.rawValue)
        }

        guard let data = data else {
            fatalError("No Gyroscope data available!")
        }

        let rotValues = data.rotationRate
        let timestamp = Date(timeInterval: data.timestamp, since: kernelBootTime())
        let rot = SensorValue(timestamp: timestamp, x: rotValues.x, y: rotValues.y, z: rotValues.z)
        lifecycleQueue.async (flags: .barrier) {
            self.rotations.append(rot)
        }
    }

    private func handle(_ data: CMMagnetometerData?, _ error: Error?) {
        if let error = error as? CMError {
            os_log("Magnetometer error: %@", log: SensorCapturer.log, type: .error, error.rawValue)
        }

        guard let data = data else {
            fatalError("No Magnetometer data available!")
        }

        let dirValues = data.magneticField
        let timestamp = Date(timeInterval: data.timestamp, since: kernelBootTime())
        let dir = SensorValue(timestamp: timestamp, x: dirValues.x, y: dirValues.y, z: dirValues.z)
        lifecycleQueue.async {
            self.directions.append(dir)
        }
    }

    func kernelBootTime() -> Date {

        var mib = [ CTL_KERN, KERN_BOOTTIME ]
        var bootTime = timeval()
        var bootTimeSize = MemoryLayout<timeval>.size

        if 0 != sysctl(&mib, UInt32(mib.count), &bootTime, &bootTimeSize, nil, 0) {
            fatalError("Could not get boot time, errno: \(errno)")
        }

        return Date(timeIntervalSince1970: TimeInterval(Double(bootTime.tv_sec) + Double(bootTime.tv_usec)/1_000_000))
    }
}
