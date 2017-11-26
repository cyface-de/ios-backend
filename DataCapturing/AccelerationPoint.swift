//
//  File.swift
//  DataCapturing
//
//  Created by Team Cyface on 24.11.17.
//  Copyright © 2017 Cyface GmbH. All rights reserved.
//

import Foundation

public class AccelerationPoint {
    var id: Int64?
    var ax: Double
    var ay: Double
    var az: Double
    var timestamp: Int64
    
    public init(id: Int64?, ax: Double, ay: Double, az: Double, timestamp: Int64) {
        self.id = id
        self.ax = ax
        self.ay = ay
        self.az = az
        self.timestamp = timestamp
    }
}
