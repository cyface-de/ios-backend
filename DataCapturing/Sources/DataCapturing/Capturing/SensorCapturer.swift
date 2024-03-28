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
import CoreMotion
import Combine
import os.log

/**
 An instance of this class is responsible for capturing data from the motion sensors of the smartphone. Currently it supports capturing from accelerometer, gyroscope and magnetometer (compass) and altimeter.

 There should be only one instance of this class used within the application.

 Timestamps for each sensor value are generated based on the current system time (by calling `Date()`).
 This might cause a slight shift by a few nanoseconds or milliseconds from the actual time when the sensor has captured the event.
 However using the timestamp provided by the event is impossible, since that timestamp is based on kernel boot time, which is not updated when the system sleeps.
 Since there is no way of knowing how long the system has sleept in between the last boot and now, we cannot use kernel boot time to get absolute data.

 - Author: Klemens Muthmann
 - Version: 3.0.0
 - Since: 6.0.0
 */
class SensorCapturer {

    // MARK: - Properties
    /// The timestamp of the previously captured acceleration. This is stored to make sure all accelerations are captured in increasing order.
    private var previousCapturedAccelerationTimestamp: TimeInterval
    /// The timestamp of the previously captured rotation. This is stored to make sure all rotations are captured in increasing order.
    private var previousCapturedRotationTimestamp: TimeInterval
    /// The timestamp of the previously captured direction. This is stored to make sure all directions are captured in increasing order.
    private var previousCapturedDirectionTimestamp: TimeInterval
    /// Receive sensor updates on this *Combine* `PassthroughSubject`.
    private let capturedValues: PassthroughSubject<Message, Never>
    /// The queue running and synchronizing read and write operations to the sensor storage objects.
    private let capturingQueue: DispatchQueue
    /// An instance of `CMMotionManager`. There should be only one instance of this type in your application.
    private let motionManager: CMMotionManager
    /// An altimeter to get altitude information.
    private let altimeter = CMAltimeter()

    // MARK: - Initializers
    /**
     Creates a new `SensorCapturer` with the appropriate queues from the `DataCapturingService`.

     - Parameters:
        - capturingQueue: The queue running and synchronizing read and write operations to the sensor storage objects.
        - accelerometerInterval: The number of updates the accelerometer provides per second (approximately). The maximum on iOS is usually 100.
        - gyroInterval: The number of updates the gyroscope provides per second (approximately). The maximum on iOS is usually 100.
        - directionsInterval: The number of updates the magnetometer provides per second (approximately). The maximum on iOS is usually 100.
     */
    init(
        capturingQueue: DispatchQueue,
        accelerometerInterval: Double = 100.0,
        gyroInterval: Double = 100.0,
        directionsInterval: Double = 100.0
    ) {
        self.capturingQueue = capturingQueue
        self.motionManager = CMMotionManager()
        self.motionManager.accelerometerUpdateInterval = 1.0 / accelerometerInterval
        self.motionManager.gyroUpdateInterval = 1.0 / gyroInterval
        self.motionManager.magnetometerUpdateInterval = 1.0 / directionsInterval

        self.previousCapturedAccelerationTimestamp = 0.0
        self.previousCapturedRotationTimestamp = 0.0
        self.previousCapturedDirectionTimestamp = 0.0

        capturedValues = PassthroughSubject<Message, Never>()
    }

    // MARK: - Methods
    /// The the sensor capturing to the storage instances `accelertions`, `rotations`, `directions` and `altitudes`.
    func start() -> AnyPublisher<Message, Never> {
        let queue = OperationQueue()
        queue.qualityOfService = QualityOfService.userInitiated
        queue.underlyingQueue = capturingQueue
        if motionManager.isAccelerometerAvailable {
            motionManager.startAccelerometerUpdates(to: queue, withHandler: handle)
        }

        if motionManager.isGyroAvailable {
            motionManager.startGyroUpdates(to: queue, withHandler: handle)
        }

        if motionManager.isDeviceMotionAvailable {
            motionManager.showsDeviceMovementDisplay = true
            motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical, to: queue, withHandler: handle)
        }

        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.startRelativeAltitudeUpdates(to: queue, withHandler: onAltitudeUpdate)
        }

        return capturedValues.eraseToAnyPublisher()
    }

    /// Stop sensor capturing.
    func stop() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        motionManager.stopDeviceMotionUpdates()
        altimeter.stopRelativeAltitudeUpdates()
    }

    /**
     The handler provided to *CoreMotion* for handling new accelerations.

     See `CMAccelerometerHandler` in the Apple documentation for futher information.

     - Parameters:
     - data: The new accelerometer data, if any is available or `nil` otherwise.
     - error: An error or `nil` if no error occured.
     */
    private func handle(_ data: CMAccelerometerData?, _ error: Error?) {
        if let error = error {
            return os_log("Accelerometer error: %{public}@", log: OSLog.capturing, type: .error, error.localizedDescription)
        }

        guard let data = data else {
            // Should only happen if the device accelerometer is broken or something similar. If this leads to problems we can substitute by a soft error handling such as a warning or something similar. However in such a case we might think everything works fine, while it really does not.
            fatalError("No Accelerometer data available!")
        }

        guard previousCapturedAccelerationTimestamp < data.timestamp else {
            return os_log("Accelerometer error: Received late value!", log: OSLog.capturing, type: .error)
        }
        previousCapturedAccelerationTimestamp = data.timestamp

        let accValues = data.acceleration
        let timestamp = Date()
        capturedValues.send(
            .capturedAcceleration(
                SensorValue(
                    timestamp: timestamp,
                    x: accValues.x,
                    y: accValues.y,
                    z: accValues.z
                )
            )
        )
    }

    /**
     The handler provided to *CoreMotion* for handling new rotations.

     See `CMGyroHandler` in the Apple documentation for futher information.

     - Parameters:
     - data: The new rotations data, if any is available or `nil` otherwise.
     - error: An error or `nil` if no error occured.
     */
    private func handle(_ data: CMGyroData?, _ error: Error?) {
        if let error = error {
            return os_log("Gyroscope error: %{public}@", log: OSLog.capturing, type: .error, error.localizedDescription)
        }

        guard let data = data else {
            fatalError("No Gyroscope data available!")
        }

        guard previousCapturedRotationTimestamp < data.timestamp else {
            return os_log("Gyroscope error: Received late value!", log: OSLog.capturing, type: .error)
        }

        let rotValues = data.rotationRate
        let timestamp = Date()
        capturedValues.send(
            .capturedRotation(
                SensorValue(
                    timestamp: timestamp,
                    x: rotValues.x,
                    y: rotValues.y,
                    z: rotValues.z
                )
            )
        )
    }

    /**
     The handler provided to *CoreMotion* for handling device motion. This is mainly used to capture cleaned

     See `CMDeviceMotionHandler` in the Apple documentation for futher information.

     - Parameters:
     - data: The new directional data, if any is available or `nil` otherwise.
     - error: An error or `nil` if no error occured.
     */
    private func handle(_ data: CMDeviceMotion?, _ error: Error?) {
        if let error = error {
            return os_log("Device Motion error: %{public}@", log: OSLog.capturing, type: .error, error.localizedDescription)
        }

        guard let data = data else {
            return os_log("No device motion data available!", log: OSLog.capturing, type: .error)
        }

        guard previousCapturedDirectionTimestamp < data.timestamp else {
            return os_log("Device Motion error: Received late value!", log: OSLog.capturing, type: .error)
        }

        let dirValues = data.magneticField
        let timestamp = Date()
        capturedValues.send(
            .capturedDirection(
                SensorValue(
                    timestamp: timestamp,
                    x: dirValues.field.x,
                    y: dirValues.field.y,
                    z: dirValues.field.z
                )
            )
        )
    }

    /// Called everytime the system has a new altitude value.
    private func onAltitudeUpdate(_ data: CMAltitudeData?, _ error: Error?) {
        if let error = error {
            os_log(
                "Device Motion error while capturing Altitude: %{public}@",
                log: OSLog.capturing,
                type: .error,
                error.localizedDescription
            )
            return
        }

        guard let data = data else {
            os_log(
                "No altitude data available!",
                log: OSLog.capturing,
                type: .error
            )
            return
        }

        capturedValues.send(
            .capturedAltitude(
                Altitude(
                    relativeAltitude: data.relativeAltitude.doubleValue,
                    pressure: data.pressure.doubleValue,
                    time: data.startTime()
                )
            )
        )
    }
}

extension CMLogItem {
    /// The boot time of the device this runs on.
    static let bootTime = Date(timeIntervalSinceNow: -ProcessInfo.processInfo.systemUptime)

    /// The actual timestamp of this item.
    func startTime() -> Date {
        return CMLogItem.bootTime.addingTimeInterval(self.timestamp)
    }
}
