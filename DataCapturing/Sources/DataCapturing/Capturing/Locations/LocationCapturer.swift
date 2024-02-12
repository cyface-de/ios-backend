/*
 * Copyright 2023 Cyface GmbH
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
import os.log
import Combine

// TODO: Transform into a Combine Publisher: https://dev.to/leogdion/combine-corelocation-part-1-publishers-delegates-164o
/**
 A class controlling the lifecycle of a *CoreLocation* session.

 This is used to start and stop location capturing and to inform intereseted parties about location changes.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 12.0.0
 */
public class LocationCapturer: NSObject {
    /// This is the maximum time between two location updates allowed before the service assumes that it does not have a valid location fix anymore.
    private static let maxAllowedTimeBetweenLocationUpdates = TimeInterval(2.0)
    //private let filter: TrackCleaner
    private var prevLocationUpdateTime: Date?
    /// The lifecycle queue of the running `Measurement`. Using the lifecycle queue prevents pause and stop events from finishing if there are still locations to be processed.
    private let lifecycleQueue: DispatchQueue
    /// Flag that is `true` if the system believes to have a valid location fix and `false` otherwise. A valid fix is determined by the time between two location updates.
    var hasFix = false
    /// *Combine* publisher to report update events to all registered parties.
    private var messagePublisher: PassthroughSubject<Message, Never>
    /// The status of the authorization given by the user to the application for getting location updates. If this is for example removed during capturing, capturing must stop or it will crash.
    private var authorizationStatus: CLAuthorizationStatus
    /**
     Provides access to the devices geo location capturing hardware (such as GPS, GLONASS, GALILEO, etc.)
     and handles geo location updates in the background.
     */
    private var coreLocationManager: LocationManager

    /**
     - Parameters:
            - lifecycleQueue: The lifecycle queue of the running `Measurement`. Using the lifecycle queue prevents pause and stop events from finishing if there are still locations to be processed.
            - locationManagerFactory: Factory class for creating a `LocationManager`. This factory is mainly used to inject different location manager implementations into an object of this class.
     */
    init(lifecycleQueue: DispatchQueue, locationManagerFactory: () -> LocationManager) {
        self.lifecycleQueue = lifecycleQueue
        self.messagePublisher = PassthroughSubject<Message, Never>()

        self.coreLocationManager = locationManagerFactory()
        self.authorizationStatus = coreLocationManager.authorizationStatus
        super.init()
    }

    /// Start capturing locations and provide a `Publisher` for receiving updates.
    func start() -> AnyPublisher<Message, Never> {
        coreLocationManager.locationDelegate = self
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            self.coreLocationManager.startUpdatingLocation()
        } else {
            self.coreLocationManager.requestAlwaysAuthorization()
            self.coreLocationManager.startUpdatingLocation()
        }
        return messagePublisher.eraseToAnyPublisher()
    }

    /// Stop capturing locations and free all resources.
    func stop() {
        self.coreLocationManager.stopUpdatingLocation()
        coreLocationManager.locationDelegate = nil
    }

    /// Checks the validity of a locations update time with respect to the previously captured location.
    ///
    /// If the time between two updates is too large, the system will send a `Message.fixLost`; if it becomes smaller again a `Message.hasFix` message is sent.
    ///
    /// Updates that have a smaller time then the previous update are reported as `.notOnTime`. Other updates are reported as `.onTime`.
    /// The calling code should decide how to handel both of these possibilities.
    private func checkUpdateTime(location: CLLocation) -> LocationTiming {
        if let prevLocationUpdateTime = self.prevLocationUpdateTime {
            guard prevLocationUpdateTime < location.timestamp else {
                os_log(.debug, log: OSLog.capturing, "Skipping location update due to late location.")
                return .notOnTime
            }

            let updateTimeIsLow = prevLocationUpdateTime.timeIntervalSinceNow < LocationCapturer.maxAllowedTimeBetweenLocationUpdates
            if updateTimeIsLow && !hasFix {
                messagePublisher.send(Message.hasFix)
                hasFix = true
            } else if !updateTimeIsLow && hasFix {
                messagePublisher.send(Message.fixLost)
                hasFix = false
            }
        }
        self.prevLocationUpdateTime = location.timestamp

        return .onTime
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationCapturer: CLLocationManagerDelegate {
    /**
     The listener method that is informed about new geo locations.

     - Remark:
     This function is one of the most critical parts of the `DataCapturingService`. It is called once per second and should not do any unncessary work.
     - Parameters:
     - manager: The location manager used.
     - didUpdateLocation: An array of the updated locations.
     */
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lifecycleQueue.sync {
            locations.filter { checkUpdateTime(location: $0) == .onTime }.forEach {
                messagePublisher.send(
                    .capturedLocation(
                        GeoLocation(
                            latitude: $0.coordinate.latitude,
                            longitude: $0.coordinate.longitude,
                            accuracy: $0.horizontalAccuracy,
                            speed: $0.speed,
                            time: $0.timestamp,
                            altitude: $0.altitude,
                            verticalAccuracy: $0.verticalAccuracy
                        )
                    )
                )
            }
        }
    }

    /**
     The listener method informed about error during location tracking. Just prints those errors to the log.

     - Parameters:
     - manager: The location manager reporting the error.
     - didFailWithError: The reported error.
     */
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        os_log("Location service failed with error: %{public}@!", log: OSLog.capturing, type: .error, error.localizedDescription)
        messagePublisher.send(Message.fixLost)
    }

    public func locationManager(_: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard self.coreLocationManager.locationDelegate != nil else {
            return
        }

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            self.coreLocationManager.startUpdatingLocation()
        default:
            self.coreLocationManager.stopUpdatingLocation()
        }
    }
}

/**
 An enumeration for reporting whether some location update is either `onTime` or is `notOnTime`.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 12.0.0
 */
enum LocationTiming {
    case onTime
    case notOnTime
}
