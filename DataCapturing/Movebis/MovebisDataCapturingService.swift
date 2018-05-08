//
//  MovebisDataCapturingService.swift
//  DataCapturing
//
//  Created by Team Cyface on 17.02.18.
//

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
 - Version: 3.0.0
 - Since: 1.0.0
 */
public class MovebisDataCapturingService: DataCapturingService {

    // MARK: Properties

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

    /** `CLLocationManager` that provides location updates to the UI,
    even when no data capturing is running.
     */
    private lazy var preCapturingLocationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.allowsBackgroundLocationUpdates = false
        // The following might shut off updates according to documentation in certain cases.
        // Do we have to start it again?
        manager.activityType = .otherNavigation
        manager.showsBackgroundLocationIndicator = false
        manager.distanceFilter = kCLDistanceFilterNone
        // Ask the user for its ok with data tracking.
        manager.requestAlwaysAuthorization()
        return manager
    }()

    // MARK: Initializers

    /**
     Creates a new `MovebisDataCapturingService` with the ability capture location
     when no data capturing runs.
     - Parameters:
     - serverConnection: An authenticated connection to a Cyface API server.
     - sensorManager: An instance of `CMMotionManager`.
     There should be only one instance of this type in your application.
     Since it seems to be impossible to create that instance inside a framework at the moment,
     you have to provide it via this parameter.
     - updateInterval: The accelerometer update interval in Hertz.
     By default this is set to the supported maximum of 100 Hz.
     - persistenceLayer: An API to store, retrieve and update captured data to the local system
     until the App can transmit it to a server.
     */
    public init(connection serverConnection: MovebisServerConnection, sensorManager manager: CMMotionManager, updateInterval interval: Double, persistenceLayer persistence: PersistenceLayer) {
        super.init(connection: serverConnection, sensorManager: manager, persistenceLayer: persistence)
    }

    override func cleanDataAfterSync(for measurement: MeasurementMO) {
        persistenceLayer.clean(measurement: measurement)
        measurement.synchronized = true
    }
}
