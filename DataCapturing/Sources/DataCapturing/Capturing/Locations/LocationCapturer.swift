//
//  File.swift
//  
//
//  Created by Klemens Muthmann on 15.03.23.
//

import Foundation
import CoreLocation
import os.log
import Combine

// TODO: Transform into a Combine Publisher: https://dev.to/leogdion/combine-corelocation-part-1-publishers-delegates-164o
// TODO: Configure OSLog properly, like in the background-test app
public class LocationCapturer: NSObject {
    private static let log = OSLog(subsystem: "de.cyface", category: "LocationCapturer")
    /// This is the maximum time between two location updates allowed before the service assumes that it does not have a valid location fix anymore.
    private static let maxAllowedTimeBetweenLocationUpdates = TimeInterval(2.0)
    //private let filter: TrackCleaner
    private var prevLocationUpdateTime: Date?
    /// Locations are captured approximately once per second on most devices. If you would like to get fewer updates this parameter controls, how many events are skipped before one is reported to your handler. The default value is 1, which reports every event. To receive fewer events you could for example set it to 5 to only receive every fifth event.
    //private let locationUpdateSkipRate: Int
    //private var geoLocationEventNumber: Int = 0
    private let lifecycleQueue: DispatchQueue
    var hasFix = false
    // var locationsCache = [LocationCacheEntry]()

    private var messagePublisher: PassthroughSubject<Message, Never>
    private var authorizationStatus: CLAuthorizationStatus

    /**
     Provides access to the devices geo location capturing hardware (such as GPS, GLONASS, GALILEO, etc.)
     and handles geo location updates in the background.
     */
    private var coreLocationManager: LocationManager

    init(/*locationUpdateSkipRate: Int = 1, filter: TrackCleaner = DefaultTrackCleaner(), */lifecycleQueue: DispatchQueue, locationManagerFactory: () -> LocationManager) {
        /*guard locationUpdateSkipRate > 0 else {
         fatalError("Invalid value 0 for locationUpdateSkipRate!")
         }*/

        //self.locationUpdateSkipRate = locationUpdateSkipRate
        //self.filter = filter
        self.lifecycleQueue = lifecycleQueue
        self.messagePublisher = PassthroughSubject<Message, Never>()

        self.coreLocationManager = locationManagerFactory()
        self.authorizationStatus = coreLocationManager.authorizationStatus
        super.init()
    }

    func start() -> AnyPublisher<Message, Never> {
        coreLocationManager.locationDelegate = self
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            //DispatchQueue.main.async { [weak self] in
            self.coreLocationManager.startUpdatingLocation()
            //}
        } else {
            self.coreLocationManager.requestAlwaysAuthorization()
        }
        return messagePublisher.eraseToAnyPublisher()
    }

    func stop() {
        //DispatchQueue.main.async {
        self.coreLocationManager.stopUpdatingLocation()
        //}
        coreLocationManager.locationDelegate = nil
    }

    private func checkUpdateTime(location: CLLocation) -> LocationTiming {
        if let prevLocationUpdateTime = self.prevLocationUpdateTime {
            guard prevLocationUpdateTime < location.timestamp else {
                os_log(.debug, log: LocationCapturer.log, "Skipping location update due to late location.")
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
            for location in locations {
                // Make sure locations are in order and check for GPS fix
                if checkUpdateTime(location: location) == .onTime {
                    messagePublisher.send(
                        .capturedLocation(
                            GeoLocation(
                                latitude: location.coordinate.latitude,
                                longitude: location.coordinate.longitude,
                                accuracy: location.horizontalAccuracy,
                                speed: location.speed,
                                time: location.timestamp,
                                altitude: location.altitude,
                                verticalAccuracy: location.verticalAccuracy
                            )
                        )
                    )
                }
                // TODO: This filtering should be done by the application
                // let isValid = filter.isValid(location: location)


                /*lifecycleQueue.async(flags: .barrier) {
                 self.locationsCache.append(geoLocation)
                 }*/

                /*geoLocationEventNumber += 1
                 if geoLocationEventNumber == 1 {
                 locationSubject.send(geoLocation)
                 }
                 if geoLocationEventNumber == locationUpdateSkipRate {
                 geoLocationEventNumber = 0
                 }*/
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
        os_log("Location service failed with error: %{public}@!", log: LocationCapturer.log, type: .error, error.localizedDescription)
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

enum LocationTiming {
    case onTime
    case notOnTime
}
