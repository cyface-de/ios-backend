//
//  Measurement.swift
//  RFR
//
//  Created by Klemens Muthmann on 31.01.23.
//

import Foundation

struct Measurement: Identifiable {
    let id: Int64
    let name: String
    let distance: Double
    let startTime: Date
    let synchronized: Bool
}

let exampleMeasurements = [
    Measurement(id: 1, name: "Fahrt zu Oma", distance: 3.0, startTime: Date(), synchronized: true),
    Measurement(id: 2, name: "Arbeit", distance: 10.0, startTime: Date(), synchronized: false),
    Measurement(id: 3, name: "Supermarkt", distance: 2.3, startTime: Date(), synchronized: true)
]
