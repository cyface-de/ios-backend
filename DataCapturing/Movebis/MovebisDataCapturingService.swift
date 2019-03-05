/*
 * Copyright 2018 Cyface GmbH
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
import CoreMotion
import os.log

/**
 A `DataCapturingService` implementation that provides the ability to capture locations
 before an actual measurement has been started.
 
 To receive the updates set the `preCapturingLocationDelegate`.
 The instance you provide will receive the updates.
 
 - Author: Klemens Muthmann
 - Version: 4.0.1
 - Since: 1.0.0
 */
public class MovebisDataCapturingService: DataCapturingService {

    // MARK: - Properties

    /// Logger used for objects of this class.
    private static let log = OSLog.init(subsystem: "MovebisDataCapturingService", category: "de.cyface")

    /**
     The delegate that gets informed about location updates.
     You may set this to `nil` if you would like to deactive location updates.
     */
    public var preCapturingLocationDelegate: CLLocationManagerDelegate? {
        didSet {
            preCapturingLocationManager.delegate = preCapturingLocationDelegate
            preCapturingLocationManager.startUpdatingLocation()
        }
        willSet(newValue) {
            if newValue==nil && preCapturingLocationDelegate != nil {
                preCapturingLocationManager.stopUpdatingLocation()
                preCapturingLocationManager.delegate = nil
            }
        }
    }

    /**
     `CLLocationManager` that provides location updates to the UI,
     even when no data capturing is running.
     */
    private lazy var preCapturingLocationManager: CLLocationManager = {
        let manager = CLLocationManager()

        // Do not start services that aren't available.
        if !CLLocationManager.locationServicesEnabled() {
            // Location services is not available.
            os_log("Location service not available!", log: MovebisDataCapturingService.log, type: .default)
            return manager
        }

        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.allowsBackgroundLocationUpdates = false
        manager.activityType = .otherNavigation
        manager.showsBackgroundLocationIndicator = false
        manager.distanceFilter = kCLDistanceFilterNone
        // Ask the user for its ok with data tracking.
        manager.requestAlwaysAuthorization()

        let authorizationStatus = CLLocationManager.authorizationStatus()
        if authorizationStatus != .authorizedWhenInUse && authorizationStatus != .authorizedAlways {
            // User has not authorized access to location information.
            os_log("Location service not authorized!", log: MovebisDataCapturingService.log, type: .default)
            return manager
        }

        return manager
    }()

    // MARK: - Initializers

    /**
     Creates a new `MovebisDataCapturingService` with the ability capture location
     when no data capturing runs.
     - Parameters:
     - connection: A connection to a Cyface API server.
     - sensorManager: An instance of `CMMotionManager`.
     There should be only one instance of this type in your application.
     Since it seems to be impossible to create that instance inside a framework at the moment,
     you have to provide it via this parameter.
     - updateInterval: The accelerometer update interval in Hertz. Default value is 100 Hertz.
     - savingInterval: The time between save operations during data capturing in seconds. Default value is 30 seconds.
     - persistenceLayer: An API to store, retrieve and update captured data to the local system until the App can transmit it to a server.
     - eventHandler: A handler for events occuring during data capturing.
     - Throws: If the networking stack for data synchronization was not successfully initialized.
     */
    public init(connection serverConnection: ServerConnection, sensorManager manager: CMMotionManager, updateInterval: Double = 100, savingInterval: Double = 30, persistenceLayer persistence: PersistenceLayer, eventHandler: @escaping ((DataCapturingEvent, Status) -> Void)) throws {
        let synchronizer = try Synchronizer(persistenceLayer: persistence, cleaner: AccelerationPointRemovalCleaner(), serverConnection: serverConnection, handler: eventHandler)
        super.init(sensorManager: manager, updateInterval: updateInterval, savingInterval: savingInterval, persistenceLayer: persistence, synchronizer: synchronizer, eventHandler: eventHandler)
    }

    // MARK: - Methods

    /**
     Starts the capturing process, notifying the provided handler of important events.
     
     This is a long running asynchronous operation.
     The provided handler is notified of its completion by receiving the event `DataCapturingEvent.serviceStarted`.
     If you need to run code and be sure that the service has started you need to listen and wait for that event to occur.

     - Throws:
     - `DataCapturingError.isPaused` if the service was paused and thus it makes no sense to start it. Use `resume()`if you want to continue.
     */
    public func start() throws {
        return try start(inContext: .bike)
    }
}
