//
//  Measurement.swift
//  DataCapturing
//
//  Created by Team Cyface on 08.05.18.
//

import Foundation

public class MeasurementEntity {
    public let identifier: Int64
    public let measurementContext: MeasurementContext

    public init(identifier: Int64, context: MeasurementContext) {
        self.identifier = identifier
        self.measurementContext = context
    }
}
