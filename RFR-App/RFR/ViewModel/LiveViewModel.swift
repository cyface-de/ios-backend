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

/**
 The view model for the live view showing the current capturing session and providing buttons to control it.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - SeeAlso: ``LiveView``
 */
class LiveViewModel: ObservableObject {
    /// How to display the current speed of the user.
    var speed: String = "0,0 km/h"
    /// How to display the average speed of the user.
    var averageSpeed: String = "0,0 km/h"
    /// The state the active ``Measurement`` is in.
    var measurementState: MeasurementState = .stopped
    /// The current position in geographic coordinates of longitude and latitude.
    var position: (Double, Double) = (0.0, 0.0)
    /// The name to display for this ``Measurement``.
    var measurementName: String = ""
    /// How to display the distance already travelled during this ``Measurement``.
    var distance: String = "0,0 m"
    /// How to display the duration this ``Measurement`` has already taken.
    var duration: String = "0:00:00"
    /// How to display the current rise during the active ``Measurement``.
    var rise: String = "0 m"
    /// How to display the avoided emissions during the active ``Measurement``.
    var avoidedEmissions: String = "0 g CO"
    var dataCapturingService: DataCapturingService

    init(_ dataCapturingService: DataCapturingService) {
        self.dataCapturingService = dataCapturingService
        self.dataCapturingService.handler.append(self.handle)
    }

    init(
        speed: String = "0,0 km/h",
        averageSpeed: String = "0,0 km/h",
        measurementState: MeasurementState = .stopped,
        position: (Double, Double) = (0.0, 0.0),
        measurementName: String = "",
        distance: String = "0,0 m",
        duration: String = "0:00:00",
        rise: String = "0 m",
        avoidedEmissions: String = "0 g CO₂",
        dataCapturingService: DataCapturingService
    ) {
        self.speed = speed
        self.averageSpeed = averageSpeed
        self.measurementState = measurementState
        self.position = position
        self.measurementName = measurementName
        self.distance = distance
        self.duration = duration
        self.rise = rise
        self.avoidedEmissions = avoidedEmissions
        self.dataCapturingService = dataCapturingService
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
                DispatchQueue.main.async { [weak self] in
                    self?.speed = String(format: "%.2d", location.speed)
                    self?.position = (location.longitude, location.latitude)
                }
            default:
                os_log("Unknown event %@.", log: OSLog.capturingEvent, type: .info, event.description)
            }
        case .error(let error):
            os_log("Event $@ failed. %@", event.description, error.localizedDescription)
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
