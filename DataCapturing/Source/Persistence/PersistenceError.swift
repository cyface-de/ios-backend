/*
 * Copyright 2023 Cyface GmbH
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

extension PersistenceError: LocalizedError {
    /// Detailed description of the causing error.
    public var errorDescription: String? {
        switch self {
        case .dataNotLoadable(measurement: let measurementIdentifier):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.PersistenceError.dataNotLoadable",
                value: "Unable to load data for measurement %i!",
                comment: ""
            )
            return String.localizedStringWithFormat(errorMessage, measurementIdentifier)
        case .measurementNotLoadable(measurementIdentifier: let measurementIdentifier):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.PersistenceError.measurementNotLoadable",
                value: "Unable to load measurement %i!",
                comment: ""
            )
            return String.localizedStringWithFormat(errorMessage, measurementIdentifier)
        case .trackNotLoadable(_, let measurement):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.PersistenceError.trackNotLoadable",
                value: "Unable to load track from measurement %i!",
                comment: ""
            )
            return String.localizedStringWithFormat(errorMessage, measurement.identifier)
        case .nonPersistentTrackEncountered(_, let measurement):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.PersistenceError.nonPersistentTrackEncountered",
                value: "Measuremet %i contains a non persistent track!",
                comment: ""
            )
            return String.localizedStringWithFormat(errorMessage, measurement.identifier)
        case .measurementsNotLoadable:
            let errorMessage = NSLocalizedString(
                "de.cyface.error.PersistenceError.measurementsNotLoadable",
                value: "Unable to load measurements from database!",
                comment: ""
            )
            return errorMessage
        case .inconsistentState:
            let errorMessage = NSLocalizedString(
                "de.cyface.error.PersistenceError.inconsistentState",
                value: "Data model is in an inconsistent state!",
                comment: ""
            )
            return errorMessage
        case .unsynchronizedMeasurement(identifier: let identifier):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.PersistenceError.unsynchronizedMeasurement",
                value: "Encountered an unsynchronized measurement where a synchronized one was expected!",
                comment: ""
            )
            return errorMessage
        case .missingTrack(let measurement):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.PersistenceError.missingTrack",
                value: "Encountered measurement %d without track to store data to!",
                comment: "")
            return String.localizedStringWithFormat(errorMessage, measurement.identifier)
        }
    }
}
