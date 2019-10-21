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
import os.log

/**
 An instance of this class is responsible for capturing data from the motion sensors of the smartphone. Currently it supports capturing from accelerometer, gyroscope and magnetometer (compass).

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 5.1.0
 */
class SensorCapturer {

    /// The log used to identify messages from this class.
    private static let log = OSLog(subsystem: "de.cyface", category: "SensorCapturer")

    /// An in memory storage for accelerations, before they are written to disk.
    var accelerations = [SensorValue]()
    /// An in memory storage for rotations, before they are written to disk.
    var rotations = [SensorValue]()
    /// An in memory storage for directions, before they are written to disk.
    var directions = [SensorValue]()
    /// The queue running and synchronizing the data capturing lifecycle.
    private let lifecycleQueue: DispatchQueue
    /// The queue running and synchronizing read and write operations to the sensor storage objects.
    private let capturingQueue: DispatchQueue
    /// An instance of `CMMotionManager`. There should be only one instance of this type in your application.
    private let motionManager: CMMotionManager
    /// `true` if the complete storage is empty. `false` otherwise.
    var isEmpty: Bool {
        return accelerations.isEmpty && rotations.isEmpty && directions.isEmpty
    }

    /**
     Creates a new `SensorCapturer` with the appropriate queues from the `DataCapturingService`.

        - Parameters:
            - lifecycleQueue: The queue running and synchronizing the data capturing lifecycle.
            - capturingQueue: The queue running and synchronizing read and write operations to the sensor storage objects.
            - motionManager: An instance of `CMMotionManager`. There should be only one instance of this type in your application.
     */
    init(lifecycleQueue: DispatchQueue, capturingQueue: DispatchQueue, motionManager: CMMotionManager) {
        self.lifecycleQueue = lifecycleQueue
        self.capturingQueue = capturingQueue
        self.motionManager = motionManager
    }

    /// The the sensor capturing to the storage instances `accelertions`, `rotations` and `directions`.
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

    /// Stop sensor capturing.
    func stop() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        motionManager.stopMagnetometerUpdates()
    }

    /**
        The handler provided to *CoreMotion* for handling new accelerations.

        See `CMAccelerometerHandler` in the Apple documentation for futher information.

     - Parameters:
        - data: The new accelerometer data, if any is available or `nil` otherwise.
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

    /**
       The handler provided to *CoreMotion* for handling new rotations.

       See `CMGyroHandler` in the Apple documentation for futher information.

    - Parameters:
       - data: The new rotations data, if any is available or `nil` otherwise.
       - error: An error or `nil` if no error occured.
    */
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

    /**
       The handler provided to *CoreMotion* for handling new directions.

       See `CMMagnetometerHandler` in the Apple documentation for futher information.

    - Parameters:
       - data: The new directional data, if any is available or `nil` otherwise.
       - error: An error or `nil` if no error occured.
    */
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

    /**
        A function providing the boot time of the device. This is required to calculate the absolute timestamp of a sensor measurement.
     */
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
