//
//  MeasurementsViewModel.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 01.07.22.
//

import Foundation
import DataCapturing

class MeasurementsViewModel: ObservableObject {
    @Published var measurements: [MeasurementViewModel]
    @Published var hasError = false
    @Published var errorMessage: String?

    init(measurements: [MeasurementViewModel] = []) {
        self.measurements = measurements
    }
}

extension MeasurementsViewModel {
    func handle(event: DataCapturingEvent, status: Status) {
        switch status {
        case .success:
            switch event {
            case .synchronizationFinished(measurement: let measurementIdentifier):
                break
            case .synchronizationStarted(measurement: let measurementIdentifier):
                break
            default:
                fatalError()
            }
        case .error(let error):
            self.hasError = true
            self.errorMessage = error.localizedDescription
        }
    }
}
