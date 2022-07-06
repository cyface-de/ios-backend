//
//  MeasurementsViewModel.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 01.07.22.
//

import Foundation

class MeasurementsViewModel: ObservableObject {
    @Published var measurements: [MeasurementViewModel]

    init(measurements: [MeasurementViewModel] = []) {
        self.measurements = measurements
    }
}
