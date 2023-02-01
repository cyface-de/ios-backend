//
//  MeasurementCellViewModel.swift
//  RFR
//
//  Created by Klemens Muthmann on 31.01.23.
//

import Foundation

class MeasurementCellViewModel {
    let measurement: Measurement
    var details: String {
        "\(measurement.startTime.formatted()) (\(measurement.distance / 1_000.0) km)"
    }
    var synchedSymbol: String {
        measurement.synchronized ? "checkmark.icloud" : "icloud.and.arrow.up"
    }

    init(measurement: Measurement) {
        self.measurement = measurement
    }
}
