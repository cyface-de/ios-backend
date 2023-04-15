/*
 * Copyright 2023 Cyface GmbH
 *
 * This file is part of the Read-for-Robots iOS App.
 *
 * The Read-for-Robots iOS App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Read-for-Robots iOS App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Read-for-Robots iOS App. If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation
import DataCapturing
import OSLog
import SwiftUI

/**
 The view model for the live view showing the current capturing session and providing buttons to control it.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - SeeAlso: ``LiveView``
 */
class LiveViewModel: ObservableObject {
    /// How to display the current speed of the user.
    @Published var speed: String
    /// How to display the average speed of the user.
    @Published var averageSpeed: String
    /// The state the active ``Measurement`` is in.
    @Published var measurementState: MeasurementState
    /// The current position in geographic coordinates of longitude and latitude.
    @Published var lastCapturedLongitude: String
    @Published var lastCapturedLatitude: String
    /// The name to display for this ``Measurement``.
    var measurementName: String
    /// How to display the distance already travelled during this ``Measurement``.
    @Published var distance: String
    /// How to display the duration this ``Measurement`` has already taken.
    @Published var duration: String
    /// How to display the current rise during the active ``Measurement``.
    @Published var rise: String
    /// How to display the avoided emissions during the active ``Measurement``.
    @Published var avoidedEmissions: String
    @Published var hasLocationFix = Image(systemName: "location")
    var dataCapturingService: DataCapturingService
    
    /// The average carbon emissions per kilometer in gramms, based on data from Statista (https://de.statista.com/infografik/25742/durchschnittliche-co2-emission-von-pkw-in-deutschland-im-jahr-2020/)
    static let averageCarbonEmissionsPerMeter = 0.117

    convenience init(_ dataCapturingService: DataCapturingService) {
        self.init(dataCapturingService: dataCapturingService)
    }

    init(
        speed: Double = 0.0,
        averageSpeed: Double = 0.0,
        measurementState: MeasurementState = .stopped,
        position: (Double, Double) = (0.0, 0.0),
        measurementName: String = "",
        distance: Double = 0.0,
        duration: TimeInterval = 0.0,
        rise: Double = 0.0,
        avoidedEmissions: Double = 0.0,
        dataCapturingService: DataCapturingService
    ) {
        guard let formattedSpeed = speedFormatter.string(from: speed as NSNumber) else {
            fatalError()
        }

        guard let formattedLongitude = locationFormatter.string(from: position.1 as NSNumber) else {
            fatalError()
        }

        guard let formattedLatitude = locationFormatter.string(from: position.0 as NSNumber) else {
            fatalError()
        }

        guard let averageFormattedSpeed = speedFormatter.string(from: averageSpeed as NSNumber) else {
            fatalError()
        }

        guard let formattedAvoidedEmissions = emissionsFormatter.string(from: avoidedEmissions as NSNumber) else {
            fatalError()
        }

        guard let formattedDistance = distanceFormatter.string(from: distance as NSNumber) else {
            fatalError()
        }

        guard let formattedDuration = timeFormatter.string(from: duration) else {
            fatalError()
        }

        guard let formattedRise = riseFormatter.string(from: rise as NSNumber) else {
            fatalError()
        }

        self.speed = "\(formattedSpeed) km/h"
        self.averageSpeed = "\(averageFormattedSpeed) km/h"
        self.measurementState = measurementState
        self.lastCapturedLongitude = formattedLongitude
        self.lastCapturedLatitude = formattedLatitude
        self.measurementName = measurementName
        self.distance = "\(formattedDistance) km"
        self.duration = formattedDuration
        self.rise = "\(formattedRise) m"
        self.avoidedEmissions = "\(formattedAvoidedEmissions) g CO₂"
        self.dataCapturingService = dataCapturingService
        self.dataCapturingService.handler.append(self.handle)
        os_log("Initializing LiveViewModel. Handler in dataCapturingService %d", self.dataCapturingService.handler.count)
    }

    func start() throws {
        try dataCapturingService.start(inMode: "BICYCLE")
    }

    func stop() throws {
        try dataCapturingService.stop()
    }

    func pause() throws {
        try dataCapturingService.pause()
    }

    func resume() throws {
        try dataCapturingService.resume()
    }

    // TODO: This should be communicated using a Combine publisher from DataCapturingService
    func handle(event: DataCapturingEvent, status: Status) {
        switch status {
        case .success:
            switch event {
                // TODO: Is it really necessary to add the event parameter here?
            case .serviceStarted(measurement: let measurementIdentifier, event: _):
                DispatchQueue.main.async { [weak self] in
                    guard let measurementIdentifier = measurementIdentifier else {
                        fatalError()
                    }

                    self?.measurementName = "Messung \(measurementIdentifier)"
                    self?.measurementState = .running
                }
            case .servicePaused(measurement: _, event: _):
                DispatchQueue.main.async { [weak self] in
                    self?.measurementState = .paused
                }
            case .serviceResumed(measurement: _, event: _):
                DispatchQueue.main.async { [weak self] in
                    self?.measurementState = .running
                }
            case .serviceStopped(measurement: _, event: _):
                DispatchQueue.main.async { [weak self] in
                    self?.measurementState = .stopped
                }
            case .geoLocationAcquired(position: let location):
                updateBasedOn(location: location)
            default:
                os_log("Unknown event %@.", log: OSLog.capturingEvent, type: .info, event.description)
            }
        case .error(let error):
            os_log("Event $@ failed. %@", event.description, error.localizedDescription)
        }
    }

    private func updateBasedOn(location: LocationCacheEntry) {
        guard let capturedMeasurement = dataCapturingService.capturedMeasurement else {
            return
        }
        let avoidedEmissions = capturedMeasurement.trackLength * LiveViewModel.averageCarbonEmissionsPerMeter
        DispatchQueue.main.async { [weak self] in
            if let formattedSpeed = speedFormatter.string(from: location.speed as NSNumber) {
                self?.speed = "\(formattedSpeed) km/h"
            }
            if let formattedLatitude = locationFormatter.string(from: location.latitude as NSNumber) {
                self?.lastCapturedLatitude = formattedLatitude
            }
            if let formattedLongitude = locationFormatter.string(from: location.longitude as NSNumber) {
                self?.lastCapturedLongitude = formattedLongitude
            }
            if let formattedAverageSpeed = speedFormatter.string(from: capturedMeasurement.averageSpeed() as NSNumber) {
                self?.averageSpeed = "\(formattedAverageSpeed) km/h"
            }
            if let formattedAvoidedEmissions = emissionsFormatter.string(from: avoidedEmissions as NSNumber) {
                self?.avoidedEmissions = "\(formattedAvoidedEmissions) g CO₂"
            }
            if let formattedDistance = distanceFormatter.string(from: capturedMeasurement.trackLength as NSNumber) {
                self?.distance = "\(formattedDistance) km"
            }
            if let formattedDuration = timeFormatter.string(from: capturedMeasurement.totalDuration()) {
                self?.duration = formattedDuration
            }
            if let formattedRise = riseFormatter.string(from: capturedMeasurement.summedHeight() as NSNumber) {
                self?.rise = formattedRise
            }
        }
    }
}

/**
 All the states a measurement may be in. The UI decides which elements to show based on this state.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
enum MeasurementState {
    /// The ``Measurement`` is active at the moment.
    case running
    /// The ``Measurement`` is paused at the moment.
    case paused
    /// The ``Measurement`` is stopped. No ``Measurement`` is currently active.
    case stopped
}

/// Some example data used to render previews of the UI.
// let viewModelExample = LiveViewModel(speed: "21 km/h", averageSpeed: "15 km/h", measurementState: .stopped, position: (51.507222, -0.1275), measurementName: "Fahrt 23", distance: "7,4 km", duration: "00:21:04", rise: "732 m", avoidedEmissions: "0,7 kg")
