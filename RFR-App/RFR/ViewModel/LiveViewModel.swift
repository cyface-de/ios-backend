//
//  LiveViewModel.swift
//  RFR
//
//  Created by Klemens Muthmann on 27.01.23.
//

import Foundation

struct LiveViewModel {
    var speed: String
    var averageSpeed: String
    var measurementState: MeasurementState
    var position: (Double, Double)
    var measurementName: String
    var distance: String
    var duration: String
    var rise: String
    var avoidedEmissions: String
}

enum MeasurementState {
    case running
    case paused
    case stopped
}

let viewModelExample = LiveViewModel(speed: "21 km/h", averageSpeed: "15 km/h", measurementState: .stopped, position: (51.507222, -0.1275), measurementName: "Fahrt 23", distance: "7,4 km", duration: "00:21:04", rise: "732 m", avoidedEmissions: "0,7 kg")
