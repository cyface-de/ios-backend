//
//  CurrentMeasurementViewModel.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 18.07.22.
//

import Foundation
import DataCapturing

/**
 The view model for displaying detail information about the currently captured measurement.

 The measurement is loaded from the Cyface backend and used to refresh the attributes necessary to show all the relevant information.
 All the attributes are formatted properly.

 - author: Klemens Muthmann
 - version: 1.0.0
 */
class CurrentMeasurementViewModel: ObservableObject {

    @Published var hasFix: UIImage
    @Published var distance: String
    @Published var speed: String
    @Published var duration: String
    @Published var latitude: String
    @Published var longitude: String
    @Published var errorMessage: String?
    private let coreDateStack: CoreDataManager
    private let measurementIdentifier: Int64?

    init(appState: ApplicationState, distance: String = "0 m", speed: String = "0 km/s", duration: String = "0 s", latitude: String = "0", longitude: String = "0") {
        self.hasFix = UIImage(named: "gps-not-available")!
        self.distance = distance
        self.speed = speed
        self.duration = duration
        self.latitude = latitude
        self.longitude = longitude
        self.coreDateStack = appState.dcs.coreDataStack
        self.measurementIdentifier = appState.dcs.currentMeasurement
        appState.dcs.handler.append(self.handle)
    }

}

extension CurrentMeasurementViewModel: CyfaceEventHandler {

    private var timeFormatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()

        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter
    }

    func handle(event: DataCapturingEvent, status: Status) {
        switch status {
        case .success:
            switch event {
            case .geoLocationFixAcquired:
                if let hasFix = UIImage(named: "gps-available") {
                    self.hasFix = hasFix
                }
            case .geoLocationFixLost:
                if let hasFix = UIImage(named: "gps-not-available") {
                    self.hasFix = hasFix
                }
            case .geoLocationAcquired(position: let location):
                let persistenceLayer = PersistenceLayer(onManager: coreDateStack)
                do {
                    if let measurementIdentifier = measurementIdentifier {
                        let measurement = try persistenceLayer.load(measurementIdentifiedBy: measurementIdentifier)

                        if let formattedDuration = timeFormatter.string(from: abs(location.timestamp.timeIntervalSince(Date(timeIntervalSince1970: Double(measurement.timestamp) / 1_000.0)))) {
                            duration = formattedDuration
                        }

                        speed = String(format: "%.2f km/s", location.speed / 3.6)
                        latitude = String(format: "%.2f", location.latitude)
                        longitude = String(format: "%.2f", location.longitude)

                        let distanceInMeters = measurement.trackLength
                        self.distance = distanceInMeters < 1_000 ? String(format: "%.2f m", distanceInMeters) : String(format: "%.2f km", distanceInMeters / 1_000)
                    }
                } catch {
                    errorMessage = error.localizedDescription
                }
            default:
                break
            }
        default:
            break
        }
    }

}
