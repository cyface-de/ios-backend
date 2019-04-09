//
//  LocationManager.swift
//  DataCapturing
//
//  Created by Team Cyface on 06.04.19.
//  Copyright © 2019 Cyface GmbH. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationManager {
    var locationDelegate: CLLocationManagerDelegate? { get set }
    func startUpdatingLocation()
    func stopUpdatingLocation()
}

extension CLLocationManager: LocationManager {
    var locationDelegate: CLLocationManagerDelegate? {
        get {
            return self.delegate
        }
        set {
            self.delegate = newValue
        }
    }
}
