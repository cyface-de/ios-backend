//
//  CurrentMeasurement.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 20.04.22.
//

import Foundation

class CurrentMeasurement: ObservableObject {
    @Published var hasFix: Bool
    @Published var duration: TimeInterval
    @Published var latitude: Double
    @Published var longitude: Double
    @Published var speed: Double
    @Published var tripDistance: Double

    init(hasFix: Bool = false, duration: TimeInterval = 0.0, latitude: Double = 0.0, longitude: Double = 0.0, speed: Double = 0.0, tripDistance: Double = 0.0) {
        self.hasFix = hasFix
        self.duration = duration
        self.latitude = latitude
        self.longitude = longitude
        self.speed = speed
        self.tripDistance = tripDistance
    }
}
