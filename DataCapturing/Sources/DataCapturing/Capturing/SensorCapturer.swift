/*
 * Copyright 2019 - 2022 Cyface GmbH
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

 There should be only one instance of this class used within the application.

 Timestamps for each sensor value are generated based on the current system time (by calling `Date()`).
 This might cause a slight shift by a few nanoseconds or milliseconds from the actual time when the sensor has captured the event.
 However using the timestamp provided by the event is impossible, since that timestamp is based on kernel boot time, which is not updated when the system sleeps.
 Since there is no way of knowing how long the system has sleept in between the last boot and now, we cannot use kernel boot time to get an absolute data.

 - Author: Klemens Muthmann
 - Version: 2.0.1
 - Since: 6.0.0
 */
public class SensorCapturer {

    // MARK: - Constants
    /// The log used to identify messages from this class.
    private static let log = OSLog(subsystem: "SensorCapturer", category: "de.cyface")

    // MARK: - Properties
    /// The measurement this data is captured for or `nil` if measurement is not active at the moment.
    var measurement: Measurement?
    /// An in memory storage for accelerations, before they are written to disk.
    var accelerations = [SensorValue]()
    /// The timestamp of the previously captured acceleration. This is stored to make sure all accelerations are captured in increasing order.
    var previousCapturedAccelerationTimestamp: TimeInterval
    /// An in memory storage for rotations, before they are written to disk.
    var rotations = [SensorValue]()
    /// The timestamp of the previously captured rotation. This is stored to make sure all rotations are captured in increasing order.
    var previousCapturedRotationTimestamp: TimeInterval
    /// An in memory storage for directions, before they are written to disk.
    var directions = [SensorValue]()
    /// The timestamp of the previously captured direction. This is stored to make sure all directions are captured in increasing order.
    var previousCapturedDirectionTimestamp: TimeInterval
    /// A cache for storing the captured altitudes, before they are written to the database.
    var altitudes = [Altitude]()
    /// The queue running and synchronizing the data capturing lifecycle.
    private let lifecycleQueue: DispatchQueue
    /// The queue running and synchronizing read and write operations to the sensor storage objects.
    private let capturingQueue: DispatchQueue
    /// An instance of `CMMotionManager`. There should be only one instance of this type in your application.
    private let motionManager: CMMotionManager
    /// `true` if the complete storage is empty. `false` otherwise.
    /// /// An altimeter to get altitude information.
    let altimeter = CMAltimeter()
    var isEmpty: Bool {
        return accelerations.isEmpty && rotations.isEmpty && directions.isEmpty
    }

    // MARK: - Initializers
    /**
     Creates a new `SensorCapturer` with the appropriate queues from the `DataCapturingService`.

     - Parameters:
     - lifecycleQueue: The queue running and synchronizing the data capturing lifecycle.
     - capturingQueue: The queue running and synchronizing read and write operations to the sensor storage objects.
     - motionManager: An instance of `CMMotionManager`. There should be only one instance of this type in your application.
     */
    init(
        lifecycleQueue: DispatchQueue,
        capturingQueue: DispatchQueue,
        accelerometerInterval: Double = 100.0,
        gyroInterval: Double = 100.0,
        directionsInterval: Double = 100.0
    ) {
        self.lifecycleQueue = lifecycleQueue
        self.capturingQueue = capturingQueue
        self.motionManager = CMMotionManager()
        self.motionManager.accelerometerUpdateInterval = 1.0 / accelerometerInterval
        self.motionManager.gyroUpdateInterval = 1.0 / gyroInterval
        self.motionManager.magnetometerUpdateInterval = 1.0 / directionsInterval

        self.previousCapturedAccelerationTimestamp = 0.0
        self.previousCapturedRotationTimestamp = 0.0
        self.previousCapturedDirectionTimestamp = 0.0
    }

    // MARK: - Methods
    /// The the sensor capturing to the storage instances `accelertions`, `rotations` and `directions`.
    func start(measurement: Measurement) {
        self.measurement = measurement

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
    }

    /// Stop sensor capturing.
    func stop() {
        self.measurement = nil
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
            return os_log("Accelerometer error: %{public}@", log: SensorCapturer.log, type: .error, error.localizedDescription)
        }

        guard let data = data else {
            // Should only happen if the device accelerometer is broken or something similar. If this leads to problems we can substitute by a soft error handling such as a warning or something similar. However in such a case we might think everything works fine, while it really does not.
            fatalError("No Accelerometer data available!")
        }

        guard previousCapturedAccelerationTimestamp < data.timestamp else {
            return os_log("Accelerometer error: Received late value!", log: SensorCapturer.log, type: .error)
        }
        previousCapturedAccelerationTimestamp = data.timestamp

        let accValues = data.acceleration
        let timestamp = Date()
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
        if let error = error {
            return os_log("Gyroscope error: %{public}@", log: SensorCapturer.log, type: .error, error.localizedDescription)
        }

        guard let data = data else {
            fatalError("No Gyroscope data available!")
        }

        guard previousCapturedRotationTimestamp < data.timestamp else {
            return os_log("Gyroscope error: Received late value!", log: SensorCapturer.log, type: .error)
        }

        let rotValues = data.rotationRate
        let timestamp = Date()
        let rot = SensorValue(timestamp: timestamp, x: rotValues.x, y: rotValues.y, z: rotValues.z)
        lifecycleQueue.async(flags: .barrier) {
            self.rotations.append(rot)
        }
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
            return os_log("Device Motion error: %{public}@", log: SensorCapturer.log, type: .error, error.localizedDescription)
        }

        guard let data = data else {
            return os_log("No device motion data available!", log: SensorCapturer.log, type: .error)
        }

        guard previousCapturedDirectionTimestamp < data.timestamp else {
            return os_log("Device Motion error: Received late value!", log: SensorCapturer.log, type: .error)
        }

        let dirValues = data.magneticField
        let timestamp = Date()
        let dir = SensorValue(timestamp: timestamp, x: dirValues.field.x, y: dirValues.field.y, z: dirValues.field.z)
        lifecycleQueue.async {
            self.directions.append(dir)
        }
    }

    /// Called everytime the system has a new altitude value.
    private func onAltitudeUpdate(data: CMAltitudeData?, error: Error?) {
        if let error = error {
            os_log(
                "Device Motion error while capturing Altitude: %{public}@",
                log: SensorCapturer.log,
                type: .error,
                error.localizedDescription
            )
            return
        }

        guard let data = data else {
            os_log(
                "No altitude data available!",
                log: SensorCapturer.log,
                type: .error
            )
            return
        }

        let altitude = Altitude(
            relativeAltitude: data.relativeAltitude.doubleValue,
            pressure: data.pressure.doubleValue,
            time: data.startTime()
        )
        if let lastTrackIndex = measurement?.tracks.count {
            measurement?.tracks[lastTrackIndex-1].altitudes.append(altitude)
        }

        lifecycleQueue.async {
            self.altitudes.append(altitude)
        }
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
