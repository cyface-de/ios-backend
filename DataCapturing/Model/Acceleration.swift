//
//  Acceleration.swift
//  DataCapturing
//
//  Created by Team Cyface on 10.05.18.
//

import Foundation

public class Acceleration {

    // MARK: - Properties

    public let timestamp: Int64
    public let x: Double
    public let y: Double
    public let z: Double

    // MARK: - Initializers

    init(timestamp: Int64, x: Double, y: Double, z: Double) {
        self.timestamp = timestamp
        self.x = x
        self.y = y
        self.z = z
    }
}
