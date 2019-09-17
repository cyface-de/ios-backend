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
 - Version: 4.2.2
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

    // MARK: - Methods

    /**
     Starts the capturing process, notifying the `eventHandler`, provided to the constructor of important events.

     The `eventHandler`, that you did provide as a parameter to this objects constructor, is notified of the completion  of the start up process by receiving the event `DataCapturingEvent.serviceStarted`.
     If you need to run code and be sure that the service has started you need to listen and wait for that event to occur.

     - Throws:
        - `DataCapturingError.isPaused` if the service was paused and thus it makes no sense to start it. Use `resume()` if you want to continue.
     */
    public func start() throws {
        return try start(inContext: .bike)
    }

    /**
     Loads only those measurements that are not captured at the moment.

     This should be used to display all finished measurements in the UI.
     Measurements are loaded from the database via CoreData and provided as `MeasurementMO` instances.
     - Attention: The returned array contains CoreData `NSManagedObject` instances (or a instances of a subclass). `NSManagedObject` is not thread safe and looses all attribute values as soon as transfered to a different thread. Handle the objects in the returned array with care and copy all required values before using them from a different thread (like for example a callback or delegate).
     - Returns: An array of measurements stored in the database without the one currently captured, if capturing is active.
     - Throws:
        - `PersistenceError.noContext` If there is no current context and no background context can be created. If this happens something is seriously wrong with CoreData.
        - Some unspecified errors from within CoreData.
     */
    public func loadInactiveMeasurements() throws -> [MeasurementMO] {
        let persistenceLayer = PersistenceLayer(onManager: self.coreDataStack)
        persistenceLayer.context = persistenceLayer.makeContext()
        let ret = try persistenceLayer.loadMeasurements()

        // Filter active measurement if any.
        if let currentMeasurement = currentMeasurement {
            return ret.filter { measurement in
                return measurement.identifier != currentMeasurement
            }
        } else {
            return ret
        }
    }
}
