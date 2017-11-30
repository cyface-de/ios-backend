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
    private (set) public var ax: Double
    private (set) public var ay: Double
    private (set) public var az: Double
    private (set) public var timestamp: Int64
    
    public init(id: Int64?, ax: Double, ay: Double, az: Double, timestamp: Int64) {
        self.id = id
        self.ax = ax
        self.ay = ay
        self.az = az
        self.timestamp = timestamp
    }
}
