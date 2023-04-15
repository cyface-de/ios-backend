//
//  MeasurementsViewModel.swift
//  RFR
//
//  Created by Klemens Muthmann on 11.04.23.
//

import Foundation
import DataCapturing
import Combine

class MeasurementsViewModel: ObservableObject {
    /// The measurements displayed by this view.
    @Published var measurements: [Measurement]
    @Published var isLoading = true
    @Published var error: Error? = nil
    let syncQueue = DispatchQueue(label: "measurements-view-operations")
    var uploadSubscription: AnyCancellable?

    // TODO: Why is it not possible to call this async? It is going to take some time for larger amounts of measurements.
    init(dataStoreStack: DataStoreStack, uploadPublisher: some Publisher<UploadStatus, Never>) {
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
                    synchronizationState: loadedMeasurement.synchronized ? .synchronized : .synchronizable)
                measurements.append(measurement)
            }
        } catch {
            self.error = error
        }
        uploadSubscription = uploadPublisher
            .receive(on: syncQueue).map {
                return self.update(measurement: $0.id, syncState: $0.status)
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.measurements, on: self)
        isLoading = false
    }

    /// Update the measurement in the measurement list and provide the updated list.
    private func update(measurement id: Int64, syncState: UploadStatusType) -> [Measurement] {
        return measurements.map { measurement in
            if measurement.id == id {
                switch syncState {
                case .started:
                    return Measurement(id: id, name: measurement.name, distance: measurement.distance, startTime: measurement.startTime, synchronizationState: .synchronizing)
                default:
                    return Measurement(id: id, name: measurement.name, distance: measurement.distance, startTime: measurement.startTime, synchronizationState: .synchronized)
                }

            } else {
                return measurement
            }
        }
    }
}
