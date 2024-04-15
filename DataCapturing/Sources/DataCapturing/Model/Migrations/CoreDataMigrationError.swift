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

/**
 Errors thrown during data migration.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 12.0.0
 */
public enum CoreDataMigrationError: Error {
    /// Occurs if the file containing the data model was missing from the bundle of the current app.
    ///
    /// This file is usually located inside a directory with the model name and the ending .momd.
    /// The file itself is identified by the resource name with either the ending .omo or .mom.
    /// As far as I know the ending .omo is used in a production build (optimized model) while mom is used in development builds.
    case modelFileNotFound(modelName: String, resourceName: String)
    case noCompatibleVersion(modelName: String)
    /// Error thrown if the iOS provided data migration code failed.
    /// The actual error is reported via the `cause` parameter.
    case migrationFailed(
        sourceModel: String,
        destinationModel: String,
        cause: Error
    )
}

extension CoreDataMigrationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .modelFileNotFound(let modelName, let resourceName):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.CoreDataMigrationError.modelFileNotFound",
                value: "No model file found at neither \"%@.momd/%@.omo\" nor \"%@.momd/%@.mom\"",
                comment: """
Explain to the user that the model file containing the CoreData model was not found at the expected location.
This location is usually inside a directory with the model name and the ending .momd.
The file itself is identified by the resource name with either the ending .omo or .mom.
As far as I know the ending .omo is used in a production build (optimized model) while mom is used in development builds.
The model name and the resource name are provided as the first and second parameter to this error.
"""
            )

            return String.localizedStringWithFormat(errorMessage, modelName, resourceName, modelName, resourceName)
        case .noCompatibleVersion(let modelName):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.CoreDataMigrationError.noCompatibleVersion",
                value: "No model file for version in model metadata of CoreData model %@",
                comment: """
Explain to the user that there was no actual file representing the model version as specified in the model meta data.
This is probably some serious inconsistency error, and most likely happended during the packing of the application.
The name of the affected model is provided as the first parameter.
"""
            )

            return String.localizedStringWithFormat(errorMessage, modelName)
        case .migrationFailed(
            sourceModel: let sourceModel,
            destinationModel: let destinationModel,
            cause: let error
        ):
            let errorMessage = NSLocalizedString(
                "de.cyface.error.CoreDataMigrationError.migrationFailed",
                value: "Data Migration failed from %@ to %@. Reason: %@.",
                comment: """
Tell the user that data migration from a previous version has failed.
The name of the source model is the first while the name of the destination model is the second parameter.
The error causing this is available as the third parameter.
""")

            return String.localizedStringWithFormat(
                errorMessage,
                sourceModel,
                destinationModel,
                error.localizedDescription
            )
        }
    }
}
