//
//  TestDataCapturingService.swift
//  DataCapturingTests
//
//  Created by Team Cyface on 17.03.19.
//  Copyright © 2019 Cyface GmbH. All rights reserved.
//

import Foundation
import CoreLocation
@testable import DataCapturing

class TestDataCapturingService : DataCapturingService {
    var timer: DispatchSourceTimer?

    override func startCapturing(savingEvery time: TimeInterval) throws {
        try super.startCapturing(savingEvery: time)
        timer = DispatchSource.makeTimerSource()
        timer!.setEventHandler {
            let location = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 10.0, longitude: 10.0), altitude: 10.0, horizontalAccuracy: 10.0, verticalAccuracy: 10.0, course: 1.0, speed: 2.0, timestamp: Date())
            self.locationManager(self.locationManager, didUpdateLocations: [location])
        }
        timer!.schedule(deadline: .now(), repeating: 1)
        timer!.resume()
    }

    override func stopCapturing() {
        super.stopCapturing()
        timer?.cancel()
        timer = nil
    }
}
