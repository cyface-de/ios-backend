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
 A protocol implemented by classes responsible for migrating from old to new data models.

 This architecture for data migration is based on information from the following Blog Post: https://williamboles.com/progressive-core-data-migration/

 - Author: Klemens Muthmann
 - Version: 1.0.2
 - Since: 4.0.0
 */
public protocol CoreDataMigratorProtocol {
    /**
     Checks if the provided store requires a migration to reach `toVersion`.

     - Parameters:
     - at: The URL pointing to the store to check
     - inBundle: The bundle containing the model and mapping files
     - Returns: `true` if migration is required, `false` otherwise
     */
    func requiresMigration(at storeURL: URL, inBundle bundle: Bundle) throws -> Bool

    /**
     Migrates the provided store to the provided version.

     - Parameters:
     - at: The URL pointing to the store to migrate
     - inBundle: The bundle containing the model and mapping files
     */
    func migrateStore(at storeURL: URL, inBundle bundle: Bundle) throws
}

/**
 An implementation of the `CoreDataMigratorProtocol` for the Cyface data model, as used by the Cyface iOS SDK.

 - Author: Klemens Muthmann
 - Version: 2.0.0
 - Since: 4.0.0
 */
public class CoreDataMigrator: CoreDataMigratorProtocol {

    // MARK: - Properties
    /// The name of the model to migrate
    private let model: String
    /// The version to migrate to.
    private let version: CoreDataMigrationVersion

    // MARK: - Initializers

    /**
     Public constructor, with the possibility to provide a version of a datastore to migrate to.

     - Parameter model: The name of the model file to migrate.
     */
    public init(
        model: String = "CyfaceModel",
        to version: CoreDataMigrationVersion = CoreDataMigrationVersion.current
    ) {
        self.model = model
        self.version = version
    }

    // MARK: - Methods

    public func requiresMigration(at storeURL: URL, inBundle bundle: Bundle) throws -> Bool {
        do {
            let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL)

            return (try CoreDataMigrationVersion.compatibleVersionForStoreMetadata(metadata, bundle, model) != version)
        } catch {
            return false
        }
    }

    public func migrateStore(at storeURL: URL, inBundle bundle: Bundle) throws {
        forceWALCheckpointingForStore(at: storeURL, inBundle: bundle)

        var currentURL = storeURL
        let migrationSteps = try self.migrationStepsForStore(at: storeURL, toVersion: version, inBundle: bundle)

        for migrationStep in migrationSteps {
            let sourceModel = migrationStep.sourceModel
            let destinationModel = migrationStep.destinationModel
            let manager = NSMigrationManager(
                sourceModel: sourceModel,
                destinationModel: destinationModel
            )
            let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(UUID().uuidString)

            do {
                try manager.migrateStore(from: currentURL,
                                         sourceType: NSSQLiteStoreType,
                                         options: nil,
                                         with: migrationStep.mappingModel,
                                         toDestinationURL: destinationURL,
                                         destinationType: NSSQLiteStoreType,
                                         destinationOptions: nil)
            } catch let error {
                throw CoreDataMigrationError.migrationFailed(
                    sourceModel: migrationStep.sourceVersion.rawValue,
                    destinationModel: migrationStep.destinationVersion.rawValue,
                    cause: error)
            }

            if currentURL != storeURL {
                // Destroy intermediate step's store
                NSPersistentStoreCoordinator.destroyStore(at: currentURL)
            }

            currentURL = destinationURL
        }

        NSPersistentStoreCoordinator.replaceStore(at: storeURL, withStoreAt: currentURL)

        if currentURL != storeURL {
            NSPersistentStoreCoordinator.destroyStore(at: currentURL)
        }
    }

    /**
     Collects all migration steps to migrate the provided store to the destination version.

     - Parameters:
        - at: The URL of the data store to migrate.
        - toVersion: The version to migrate to.
        - inBundle: The bundle containing the model and mapping files.
     - Returns: An array of `CoreDataMigrationStep` instances ordered from the oldest to the newest.
     - Throws: ``CoreDataMigrationError/modelFileNotFound(modelName:resourceName:)`` If the model file was not present in the provided `Bundle`.
     */
    private func migrationStepsForStore(at storeURL: URL, toVersion destinationVersion: CoreDataMigrationVersion, inBundle bundle: Bundle) throws -> [CoreDataMigrationStep] {
        guard let metadata = NSPersistentStoreCoordinator.metadata(at: storeURL) else {
            fatalError("Unable to load metadata for persistent store: \(storeURL).")
        }

        guard let sourceVersion = try CoreDataMigrationVersion.compatibleVersionForStoreMetadata(metadata, bundle, model) else {
            fatalError("Unknown store version at URL \(storeURL).")
        }

        return try migrationSteps(fromSourceVersion: sourceVersion, toDestinationVersion: destinationVersion, inBundle: bundle)
    }

    /**
     Creates migration steps between a source and a destination version of the Cyface data model.

     - Parameters:
        - fromSourceVersion: The initial source version to start creating migration steps from.
        - toDestinationVersion: The final destination version to end creating migration steps for.
        - inBundle: The bundle containing the model and mapping files.
     - Returns: An array of `CoreDataMigrationStep` instances necessary to reach `toDestinationVersion` from `fromSourceVersion`, ordered from the oldest to the newest version.
     */
    private func migrationSteps(fromSourceVersion sourceVersion: CoreDataMigrationVersion, toDestinationVersion destinationVersion: CoreDataMigrationVersion, inBundle bundle: Bundle) throws -> [CoreDataMigrationStep] {
        var sourceVersion = sourceVersion
        var migrationSteps = [CoreDataMigrationStep]()

        while sourceVersion != destinationVersion, let nextVersion = sourceVersion.nextVersion() {
            let migrationStep = try CoreDataMigrationStep(
                modelName: model,
                sourceVersion: sourceVersion,
                destinationVersion: nextVersion,
                bundle: bundle
            )
            migrationSteps.append(migrationStep)

            sourceVersion = nextVersion
        }

        return migrationSteps
    }

    /**
     Helper method that forces cached data in the data store to be finialized.

     - Parameters:
        - at: The URL pointing to the store file to be finalized. This is only valid for SQLite stores.
        - inBundle: The bundle containing the store file.
     */
    func forceWALCheckpointingForStore(at storeURL: URL, inBundle bundle: Bundle) {
        guard let metadata = NSPersistentStoreCoordinator.metadata(at: storeURL),
              let currentModel = NSManagedObjectModel.compatibleModelForStoreMetadata(metadata, bundle) else {
            return
        }

        do {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: currentModel)

            let options = [NSSQLitePragmasOption: ["journal_mode": "DELETE"]]
            let store = persistentStoreCoordinator.addPersistentStore(at: storeURL, options: options)
            try persistentStoreCoordinator.remove(store)
        } catch let error {
            fatalError("Failed to force WaL checkpointing, error \(error)")
        }
    }
}

extension NSPersistentStoreCoordinator {

    // MARK: - Destroy

    /**
     Utility extension for destroying a store located at the provided `URL` and manged by this coordinator.

     - Parameter at: The location of the store to destroy.
     */
    static func destroyStore(at storeURL: URL) {
        do {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel())
            try persistentStoreCoordinator.destroyPersistentStore(at: storeURL, ofType: NSSQLiteStoreType, options: nil)
        } catch let error {
            fatalError("Failed to destroy persistent store at \(storeURL), error: \(error)")
        }
    }

    // MARK: - Replace

    /**
     Utility extension to replace a store file with another one.

     - Parameters:
        - at: The target that should be replaced.
        - withStoreAt: The source to replace the target.
     */
    static func replaceStore(at targetURL: URL, withStoreAt sourceURL: URL) {
        do {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel())
            try persistentStoreCoordinator.replacePersistentStore(
                at: targetURL,
                destinationOptions: nil,
                withPersistentStoreFrom: sourceURL,
                sourceOptions: nil,
                ofType: NSSQLiteStoreType
            )
        } catch let error {
            fatalError("Failed to replace persistent store at \(targetURL) with \(sourceURL), error: \(error)")
        }
    }

    // MARK: - Meta

    /**
     Provides the meta data for the store at the provided location.

     - Parameter at: The `URL` to the store file, for which metadata is requested.
     - Returns: The meta data dictionary for the provided store file.
     */
    static func metadata(at storeURL: URL) -> [String: Any]? {
        return try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL, options: nil)
    }

    // MARK: - Add

    /**
     Adds the store at the provided location to this coordinator.

     - Parameters:
     - at: The file location of the store to add
     - options: Any additional options required to add that store
     - Returns: The newly created `NSPersistentStore`
     */
    func addPersistentStore(at storeURL: URL, options: [AnyHashable: Any]) -> NSPersistentStore {
        do {
            return try addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
        } catch let error {
            fatalError("Failed to add persistent store to coordinator, error: \(error)")
        }
    }
}

extension NSManagedObjectModel {

    // MARK: - Resource

    /**
     Provides the managed object model for the persistent store identified by the provided resource inside the provided bundle.

     - Parameters:
        - forResource: The resource to create the managed object model for
        - inBundle: The bundle containing the provided resource
        - withModelName: The name of the model file to load the managed object from (without extension).
     - Returns: The created `NSManagedObjectModel`
     */
    static func managedObjectModel(forResource resource: String, inBundle bundle: Bundle, withModelName name: String) throws -> NSManagedObjectModel {
        let subdirectory = "CyfaceModel.momd"
        let omoURL = bundle.url(forResource: resource, withExtension: "omo", subdirectory: subdirectory) // optimized model file
        let momURL = bundle.url(forResource: resource, withExtension: "mom", subdirectory: subdirectory)
        let embeddedMOMURL = bundle.url(forResource: resource, withExtension: "mom", subdirectory: "DataCapturing_DataCapturing.bundle/\(subdirectory)")

        guard let url = omoURL ?? momURL ?? embeddedMOMURL else {
            throw CoreDataMigrationError.modelFileNotFound(modelName: name, resourceName: resource)
        }

        guard let model = NSManagedObjectModel(contentsOf: url) else {
            fatalError("Unable to load model in bundle!")
        }

        return model
    }

    // MARK: - Compatible

    /**
     Creates an `NSManagedObjectModel` based on some meta data.

     - Parameters:
        - metadata: The dictionary of meta data to check
        - bundle: The bundle containing the model file
     - Returns: An `NSManagedObjectModel` created from the provided meta data if a compatible model file has been found inside the provided bundle.
     */
    static func compatibleModelForStoreMetadata(_ metadata: [String: Any], _ bundle: Bundle) -> NSManagedObjectModel? {
        return NSManagedObjectModel.mergedModel(from: [bundle], forStoreMetadata: metadata)
    }
}

private extension CoreDataMigrationVersion {

    // MARK: - Compatible

    /**
     Checks for a version that is compatible with the provided meta data inside the provided bundle.

     - Parameters:
        - metadata: The meta data to use to search for a version.
        - bundle: The bundle to search for compatible model version files.
        - name: The name of the model to load the compatible version from.
     - Returns: Either the retrieved version or `nil` if no model file with a compatible version has been found inside the provided bundle.
     - Throws: ``CoreDataMigrationError/noCompatibleVersion(modelName:)`` If the model file was not present in the provided `Bundle`.
     */
    static func compatibleVersionForStoreMetadata(_ metadata: [String: Any], _ bundle: Bundle, _ name: String) throws -> CoreDataMigrationVersion? {
        let compatibleVersion = CoreDataMigrationVersion.allCases.compactMap { versionName in
            let rawVersionName = versionName.rawValue
            do {
                let model = try NSManagedObjectModel.managedObjectModel(
                    forResource: rawVersionName,
                    inBundle: bundle,
                    withModelName: name
                )

                return (model, versionName)
            } catch {
                return nil
            }
        }.filter { (modelWithVersion: (NSManagedObjectModel, CoreDataMigrationVersion)) in
            let model = modelWithVersion.0
            return model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
        }.first

        guard let version = compatibleVersion?.1 else {
            throw CoreDataMigrationError.noCompatibleVersion(modelName: name)
        }

        return version
    }
}
