//
//  TestLocationManager.swift
//  DataCapturingTests
//
//  Created by Team Cyface on 06.04.19.
//  Copyright © 2019 Cyface GmbH. All rights reserved.
//

import Foundation
import CoreLocation
@testable import DataCapturing

class TestLocationManager: LocationManager {
    weak var locationDelegate: CLLocationManagerDelegate?

    func startUpdatingLocation() {
        print("start updating location")
    }

    func stopUpdatingLocation() {
        print("stop updating location")
    }
}
