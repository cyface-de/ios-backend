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

// TODO: Remove this
class ControlBarViewModel: ObservableObject {

    let measurement: DataCapturing.Measurement
    @Published var showError = false
    var error: Error?

    init(measurement: DataCapturing.Measurement) {
        self.measurement = measurement
    }

    func onPlayPausePressed() {
        do {
            if measurement.isRunning {
                try measurement.pause()
            } else if measurement.isPaused {
                try measurement.resume()
            } else {
                try measurement.start(inMode: "BICYCLE")
            }
        } catch {
            handleError(error)
        }
    }

    func onStopPressed() {
        do {
            try measurement.stop()
        } catch {
            handleError(error)
        }
    }

    private func handleError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            self.error = error
            self.showError = true
        }
    }
}
