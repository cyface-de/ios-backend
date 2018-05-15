//
//  GeoLocation.swift
//  DataCapturing
//
//  Created by Team Cyface on 10.05.18.
//

import Foundation

public class GeoLocation {

    // MARK: - Properties

    public let latitude: Double
    public let longitude: Double
    public let accuracy: Double
    public let speed: Double
    public let timestamp: Int64

    // MARK: - Initializers

    init(latitude: Double, longitude: Double, accuracy: Double, speed: Double, timestamp: Int64) {
        self.latitude = latitude
        self.longitude = longitude
        self.accuracy = accuracy
        self.speed = speed
        self.timestamp = timestamp
    }
}
