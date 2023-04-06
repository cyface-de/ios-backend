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
    private let filter: TrackCleaner
    private var prevLocationUpdateTime: Date?
    /// Locations are captured approximately once per second on most devices. If you would like to get fewer updates this parameter controls, how many events are skipped before one is reported to your handler. The default value is 1, which reports every event. To receive fewer events you could for example set it to 5 to only receive every fifth event.
    private let locationUpdateSkipRate: Int
    private var geoLocationEventNumber: Int = 0
    private let lifecycleQueue: DispatchQueue
    var hasFix = false
    var locationsCache = [LocationCacheEntry]()

    let locationSubject = PassthroughSubject<LocationCacheEntry, Never>()
    let fixSubject = PassthroughSubject<Bool, Never>()

    /**
     Provides access to the devices geo location capturing hardware (such as GPS, GLONASS, GALILEO, etc.)
     and handles geo location updates in the background.
     */
    lazy var coreLocationManager: LocationManager = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        manager.activityType = .other
        manager.showsBackgroundLocationIndicator = true
        manager.distanceFilter = kCLDistanceFilterNone
        manager.requestAlwaysAuthorization()
        return manager
    }()

    init(locationUpdateSkipRate: Int = 1, filter: TrackCleaner = DefaultTrackCleaner(), lifecycleQueue: DispatchQueue) {
        guard locationUpdateSkipRate > 0 else {
            fatalError("Invalid value 0 for locationUpdateSkipRate!")
        }

        self.locationUpdateSkipRate = locationUpdateSkipRate
        self.filter = filter
        self.lifecycleQueue = lifecycleQueue
        super.init()
    }
    func start() {
        coreLocationManager.locationDelegate = self
        DispatchQueue.main.async { [weak self] in
            self?.coreLocationManager.startUpdatingLocation()
        }
    }
    func stop() {
        DispatchQueue.main.async {
            self.coreLocationManager.stopUpdatingLocation()
        }
        coreLocationManager.locationDelegate = nil
    }

    private func checkUpdateTime(location: CLLocation) -> LocationTiming {
        if let prevLocationUpdateTime = self.prevLocationUpdateTime {
            guard prevLocationUpdateTime < location.timestamp else {
                os_log(.debug, log: LocationCapturer.log, "Skipping location update due to late location.")
                return .notOnTime
            }

            if prevLocationUpdateTime.timeIntervalSinceNow < LocationCapturer.maxAllowedTimeBetweenLocationUpdates {
                fixSubject.send(true)
            } else {
                fixSubject.send(false)
            }
        } else {
            fixSubject.send(false)
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
        for location in locations {
            // Make sure locations are in order and check for GPS fix
            guard checkUpdateTime(location: location) == .onTime else {
                continue
            }

            let isValid = filter.isValid(location: location)
            let geoLocation = LocationCacheEntry(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                accuracy: location.horizontalAccuracy,
                speed: location.speed,
                timestamp: location.timestamp,
                isValid: isValid)

            lifecycleQueue.async(flags: .barrier) {
                self.locationsCache.append(geoLocation)
            }

            geoLocationEventNumber += 1
            if geoLocationEventNumber == 1 {
                locationSubject.send(geoLocation)
            }
            if geoLocationEventNumber == locationUpdateSkipRate {
                geoLocationEventNumber = 0
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
        hasFix = false
    }
}

enum LocationTiming {
    case onTime
    case notOnTime
}
