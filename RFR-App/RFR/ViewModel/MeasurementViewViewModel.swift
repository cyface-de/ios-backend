//
//  MeasurementViewViewModel.swift
//  RFR
//
//  Created by Klemens Muthmann on 31.01.23.
//

import Foundation

class MeasurementViewViewModel {
    var title: String {
        "Fahrt zu Oma"
    }
    var heightProfile: [Altitude] {
        [
            Altitude(id: 0, timestamp: Date(timeIntervalSince1970: 1675170395), height: 5.0),
            Altitude(id: 1, timestamp: Date(timeIntervalSince1970: 1675173995), height: 10.2),
            Altitude(id: 2, timestamp: Date(timeIntervalSince1970: 1675177595), height: 15.7),
            Altitude(id: 3, timestamp: Date(timeIntervalSince1970: 1675181195), height: 12.3)
        ]
    }
}
