//
//  MeasurementsViewModel.swift
//  RFR
//
//  Created by Klemens Muthmann on 11.04.23.
//

import Foundation
import DataCapturing

class MeasurementsViewModel: ObservableObject {
    /// The measurements displayed by this view.
    var measurements: [Measurement]
    @Published var isLoading = true
    @Published var error: Error? = nil

    // TODO: Why is it not possible to call this async? It is going to take some time for larger amounts of measurements.
    init(dataStoreStack: DataStoreStack) {
        self.measurements = [Measurement]()
        let dao = dataStoreStack.persistenceLayer()
        do {
            let loadedMeasurements = try dao.loadMeasurements()
            for loadedMeasurement in loadedMeasurements {
                let measurement = Measurement(
                    id: loadedMeasurement.identifier,
                    name: "Measurement \(loadedMeasurement.identifier)",
                    distance: loadedMeasurement.trackLength,
                    startTime: loadedMeasurement.time,
                    synchronized: loadedMeasurement.synchronized)
                measurements.append(measurement)
            }
        } catch {
            self.error = error
        }
        isLoading = false
    }
}
