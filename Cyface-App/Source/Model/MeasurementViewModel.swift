//
//  MeasurementViewModel.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 01.07.22.
//

import Foundation
import DataCapturing

struct MeasurementViewModel: Identifiable {
    var synchronizationFailed = false
    var synchronizing = false
    var distance = 0.0
    var formattedDistance: String {
        get {
            distance < 1_000 ? String(format: "%.0f m", distance) : String(format: "%.2f km", distance / 1_000)
        }
    }
    let id: Int64
}
