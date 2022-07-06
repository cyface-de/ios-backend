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
    let id: Int64
}
