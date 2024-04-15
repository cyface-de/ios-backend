/*
 * Copyright 2019-2024 Cyface GmbH
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
import CoreData

/**
 One step in a data model migration, migrating the database from one version to the following one.

 - Author: Klemens Muthmann
 - Version: 2.0.0
 - Since: 4.0.0
 */
struct CoreDataMigrationStep {
    /// The source CoreData object model
    let sourceModel: NSManagedObjectModel
    /// The destination CoreData object model
    let destinationModel: NSManagedObjectModel
    /// The mapping between both models.
    let mappingModel: NSMappingModel
    /// The Version of the source model to migrate from.
    let sourceVersion: CoreDataMigrationVersion
    /// The Version of the destination model to migrate to.
    let destinationVersion: CoreDataMigrationVersion

    // MARK: - Initializers

    /**
     Creates a new completely initialized instance of this class. between two versions

     - Parameters:
        - modelName: The name of the model to migrate.
        - sourceVersion: The source version to migrate from.
        - destinationVersion: The destination version to migrate to.
        - bundle: The bundle containing the model and mapping files.
     - Throws: ``CoreDataMigrationError/modelFileNotFound(modelName:resourceName:)`` If the model file is missing in the application bundle.
     */
    init(modelName: String, sourceVersion: CoreDataMigrationVersion, destinationVersion: CoreDataMigrationVersion, bundle: Bundle) throws {
        let sourceModel = try NSManagedObjectModel.managedObjectModel(
            forResource: sourceVersion.rawValue,
            inBundle: bundle,
            withModelName: modelName
        )
        let destinationModel = try NSManagedObjectModel.managedObjectModel(
            forResource: destinationVersion.rawValue,
            inBundle: bundle,
            withModelName: modelName
        )

        guard let mappingModel = CoreDataMigrationStep.mappingModel(
            fromSourceModel: sourceModel,
            toDestinationModel: destinationModel,
            inBundle: bundle) else {
            fatalError("Expected model mapping not present")
        }

        self.sourceModel = sourceModel
        self.destinationModel = destinationModel
        self.mappingModel = mappingModel
        self.sourceVersion = sourceVersion
        self.destinationVersion = destinationVersion
    }

    // MARK: - Methods

    /**
     Provides the mapping model between `fromSourceModel` and `toDestinationModel` `NSManagedObjectModel` instances.

     - Parameters:
        - fromSourceModel: The source model to provide a mapping for
        - toDestinationModel: The destination model to provide a mapping for
        - inBundle: The bundle containing the model and potential mapping files
     - Returns: The created `NSMappingModel`
     */
    private static func mappingModel(fromSourceModel sourceModel: NSManagedObjectModel, toDestinationModel destinationModel: NSManagedObjectModel, inBundle bundle: Bundle) -> NSMappingModel? {
        guard let customMapping = customMappingModel(fromSourceModel: sourceModel, toDestinationModel: destinationModel, inBundle: bundle) else {
            return inferredMappingModel(fromSourceModel: sourceModel, toDestinationModel: destinationModel)
        }

        return customMapping
    }

    /**
     Tries to create an automatically inferred mapping model from `fromSourceModel` to `toDestinationModel`.

     - Parameters:
        - fromSourceModel: The source model to infer the mapping from
        - toDestinationModel: The destination model to infer the mapping to
     - Returns: The inferred `NSMappingModel` or `nil` if no model could be inferred.
     */
    private static func inferredMappingModel(fromSourceModel sourceModel: NSManagedObjectModel, toDestinationModel destinationModel: NSManagedObjectModel) -> NSMappingModel? {
        return try? NSMappingModel.inferredMappingModel(forSourceModel: sourceModel, destinationModel: destinationModel)
    }

    /**
     Tries to load a custom mapping model from `fromSourceModel` to `toDestinationModel`.

     - Parameters:
        - fromSourceModel: The source model to load the mapping from for.
        - toDestinationModel: The destination model to load the mapping to for.
     - Returns: The loaded `NSMappingModel` if one was available or `nil` if there was not.
     */
    private static func customMappingModel(fromSourceModel sourceModel: NSManagedObjectModel, toDestinationModel destinationModel: NSManagedObjectModel, inBundle bundle: Bundle) -> NSMappingModel? {
        return NSMappingModel(from: [bundle], forSourceModel: sourceModel, destinationModel: destinationModel)
    }
}
