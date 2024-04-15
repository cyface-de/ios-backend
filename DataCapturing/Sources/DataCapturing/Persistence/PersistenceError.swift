/*
 * Copyright 2024 Cyface GmbH
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

/**
 A structure for all the errors thrown from saving data to permanent storage..

 - Author: Klemens Muthmann
 - Version: 3.2.0
 - Since: 2.3.0
 */
public enum PersistenceError: Error {
    /// If a measurement was not loaded successfully.
    case measurementNotLoadable(UInt64)
    /// If a track from a measurement could not be loaded
    case trackNotLoadable(Track, FinishedMeasurement)
    /// If a track was not persistent (i.e. had not valid objectId) at a place where only persistent tracks are valid
    case nonPersistentTrackEncountered(Track, FinishedMeasurement)
    /// If measurements could not be loaded in bulk.
    case measurementsNotLoadable
    /// If some data belonging to a measurement could not be loaded.
    case dataNotLoadable(measurement: UInt64)
    /// If it is impossible to load the last generated identifier. This can only happen if the system settings have been tempered with.
    case inconsistentState
    /// On trying to load a not yet synchronized `Measurement`. This is usually a `Measurement` with en `objectId` of `nil`.
    case unsynchronizedMeasurement(identifier: UInt64)
    /// Thrown if interaction happened with an ``UploadSession`` that was not registered and thus not available. The provided ``FinishedMeasurement``is the measurement the session tried to synchronize.
    case sessionNotRegistered(FinishedMeasurement)
}

extension PersistenceError: LocalizedError {
    // Localized error description, with further information about the error.
    public var errorDescription: String? {
        switch self {
        case .measurementNotLoadable(let measurementIdentifier):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.PersistenceError.measurementNotLoadable",
                value: "Unable to load measurement %d!",
                comment: """
                Tell the user that a measurement was not loaded successfully. \
                The first parameter is the identifier of the measurement.
                """
            )
            return String.localizedStringWithFormat(errorMessage, measurementIdentifier)
        case .trackNotLoadable(_, let measurement):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.PersistenceError.trackNotLoadable",
                value: "Unable to load track from measurement %d!",
                comment: """
                Tell the user that the system was unable to load a track from a measurement. \
                The first parameter is the measurement the track belongs to.
                """
            )
            return String.localizedStringWithFormat(errorMessage, measurement.identifier)
        case .nonPersistentTrackEncountered(_, let measurement):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.PersistenceError.nonPersistentTrackEncountered",
                value: "Unable to update values of non persistent track from measurement %d!",
                comment: """
                Tell the user that the system was unable to update a track, since that track was not yet saved, \
                to the database. The first parameter is the identifier of the measurement the track belongs to.
                """
            )
            return String.localizedStringWithFormat(errorMessage, measurement.identifier)
        case .dataNotLoadable(measurement: let measurementIdentifier):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.PersistenceError.dataNotLoadable",
                value: "Unable to load some data belonging to measurement %d!",
                comment: """
                Tell the user that the system was unable to load data belonging to some measurement. \
                The first parameter is the identifier of the measurement!
                """
            )
            return String.localizedStringWithFormat(errorMessage, measurementIdentifier)
        case .inconsistentState:
            let errorMessage = NSLocalizedString(
                "de.cyface.error.PersistenceError.inconsistentState",
                value: "Data storage is in an inconsistent state!",
                comment: """
                Tell the user that the data storage was in an inconsistent state and could not be accessed!
                """
            )
            return String.localizedStringWithFormat(errorMessage)
        case .unsynchronizedMeasurement(identifier: let measurementIdentifier):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.PersistenceError.unsynchronizedMeasurement",
                value: "Failed to load measurement %d since it was not yet synchronized with the data storage!",
                comment: """
                Tell the user that the measurement that was supposed to be loaded was not yet saved!
                """
            )
            return String.localizedStringWithFormat(errorMessage, measurementIdentifier)
        case .measurementsNotLoadable:
            let errorMessage = NSLocalizedString(
                "de.cyface.error.PersistenceError.measurementsNotLoadable",
                value: "Multiple measurements from the data storage have not been loadable!",
                comment: """
                Tell the user that measurements from the database are not loadable. \
                The reason is unknown at this point.
                """
            )
            return String.localizedStringWithFormat(errorMessage)
        case .sessionNotRegistered(let measurement):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.PersistenceError.sessionNotRegistered",
                comment: """
                Something happended while trying to save to or load from an UploadSession that was stored to the database. The identifier of the affected measurement is provided as the first parameter.
                """
            )
            return String.localizedStringWithFormat(errorMessage, measurement.identifier)
        }
    }
}
