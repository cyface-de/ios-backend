/*
 * Copyright 2022 Cyface GmbH
 *
 * This file is part of the Cyface SDK for iOS.
 *
 * The Cyface SDK for iOS is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Cyface SDK for iOS is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Cyface SDK for iOS. If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation
import DataCapturing

/// The MVVM view model backing the list of measurements shown on the main screen.
///
/// - author: Klemens Muthmann
/// - version: 1.0.0
/// - since: 4.0.0
class MeasurementsViewModel: ObservableObject {
    /// The measurements currently shown in the list
    @Published var measurements: [MeasurementViewModel]
    /// Whether this view should display an error message or not. If it should the flag is `true` otherwise it is `false`.
    @Published var hasError = false
    /// The error message to show, if any.
    @Published var errorMessage: String?

    /// Initializes a new view model, with a default empty list of individual ``MeasurementViewModel`` instances.
    init(measurements: [MeasurementViewModel] = []) {
        self.measurements = measurements
    }
}

extension MeasurementsViewModel {
    /// A Cyface data capturing handler for `DataCapturingEvents`. This one only reacts to updates on measurement synchronization, updating the list of measurements on the `MeasurementsViewModel`.
    ///
    /// Measurements that are successfully synchronized are deleted and if the synchronization failed for some reason an error indicator is shown.
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
