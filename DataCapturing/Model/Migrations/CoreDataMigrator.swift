//
//  CoreDataMigratorProtocol.swift
//  DataCapturing
//
//  Created by Team Cyface on 27.03.19.
//  Copyright © 2019 Cyface GmbH. All rights reserved.
//

import Foundation
import CoreData

protocol CoreDataMigratorProtocol {
    func requiresMigration(at storeURL: URL, toVersion version: CoreDataMigrationVersion, inBundle bundle: Bundle) -> Bool
    func migrateStore(at storeURL: URL, toVersion version: CoreDataMigrationVersion, inBundle bundle: Bundle)
}

class CoreDataMigrator: CoreDataMigratorProtocol {

    // MARK: - Methods
    func requiresMigration(at storeURL: URL, toVersion version: CoreDataMigrationVersion, inBundle bundle: Bundle = Bundle.main) -> Bool {
        guard let metadata = NSPersistentStoreCoordinator.metadata(at: storeURL) else {
            return false
        }

        return (CoreDataMigrationVersion.compatibleVersionForStoreMetadata(metadata, bundle) != version)
    }

    func migrateStore(at storeURL: URL, toVersion version: CoreDataMigrationVersion, inBundle bundle: Bundle = Bundle.main) {
        forceWALCheckpointingForStore(at: storeURL, inBundle: bundle)

        var currentURL = storeURL
        let migrationSteps = self.migrationStepsForStore(at: storeURL, toVersion: version, inBundle: bundle)

        for migrationStep in migrationSteps {
            let manager = NSMigrationManager(sourceModel: migrationStep.sourceModel, destinationModel: migrationStep.destinationModel)
            let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(UUID().uuidString)

            do {
                try manager.migrateStore(from: currentURL, sourceType: NSSQLiteStoreType, options: nil, with: migrationStep.mappingModel, toDestinationURL: destinationURL, destinationType: NSSQLiteStoreType, destinationOptions: nil)
            } catch let error {
                fatalError("Migration failed from \(migrationStep.sourceModel) to \(migrationStep.destinationModel), error: \(error)")
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

    private func migrationStepsForStore(at storeURL: URL, toVersion destinationVersion: CoreDataMigrationVersion, inBundle bundle: Bundle) -> [CoreDataMigrationStep] {
        guard let metadata = NSPersistentStoreCoordinator.metadata(at: storeURL), let sourceVersion = CoreDataMigrationVersion.compatibleVersionForStoreMetadata(metadata, bundle) else {
            fatalError("Unknown store version at URL \(storeURL).")
        }

        return migrationSteps(fromSourceVersion: sourceVersion, toDestinationVersion: destinationVersion, inBundle: bundle)
    }

    private func migrationSteps(fromSourceVersion sourceVersion: CoreDataMigrationVersion, toDestinationVersion destinationVersion: CoreDataMigrationVersion, inBundle bundle: Bundle) -> [CoreDataMigrationStep] {
        var sourceVersion = sourceVersion
        var migrationSteps = [CoreDataMigrationStep]()

        while sourceVersion != destinationVersion, let nextVersion = sourceVersion.nextVersion() {
            let migrationStep = CoreDataMigrationStep(sourceVersion: sourceVersion, destinationVersion: nextVersion, bundle: bundle)
            migrationSteps.append(migrationStep)

            sourceVersion = nextVersion
        }

        return migrationSteps
    }

    func forceWALCheckpointingForStore(at storeURL: URL, inBundle bundle: Bundle) {
        guard let metadata = NSPersistentStoreCoordinator.metadata(at: storeURL), let currentModel = NSManagedObjectModel.compatibleModelForStoreMetadata(metadata, bundle) else {
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

    static func destroyStore(at storeURL: URL) {
        do {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel())
            try persistentStoreCoordinator.destroyPersistentStore(at: storeURL, ofType: NSSQLiteStoreType, options: nil)
        } catch let error {
            fatalError("Failed to destroy persistent store at \(storeURL), error: \(error)")
        }
    }

    // MARK: - Replace

    static func replaceStore(at targetURL: URL, withStoreAt sourceURL: URL) {
        do {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel())
            try persistentStoreCoordinator.replacePersistentStore(at: targetURL, destinationOptions: nil, withPersistentStoreFrom: sourceURL, sourceOptions: nil, ofType: NSSQLiteStoreType)
        } catch let error {
            fatalError("Failed to replace persistent store at \(targetURL) with \(sourceURL), error: \(error)")
        }
    }

    // MARK: - Meta

    static func metadata(at storeURL: URL) -> [String: Any]? {
        return try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL, options: nil)
    }

    // MARK: - Add

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

    static func managedObjectModel(forResource resource: String, inBundle bundle: Bundle) -> NSManagedObjectModel {
        let subdirectory = "CyfaceModel.momd"
        let omoURL = bundle.url(forResource: resource, withExtension: "omo", subdirectory: subdirectory) // optimized model file
        let momURL = bundle.url(forResource: resource, withExtension: "mom", subdirectory: subdirectory)

        guard let url = omoURL ?? momURL else {
            fatalError("Unable to find model in bundle!")
        }

        guard let model = NSManagedObjectModel(contentsOf: url) else {
            fatalError("Unable to load model in bundle!")
        }

        return model
    }

    // MARK: - Compatible

    static func compatibleModelForStoreMetadata(_ metadata: [String: Any], _ bundle: Bundle) -> NSManagedObjectModel? {
        return NSManagedObjectModel.mergedModel(from: [bundle], forStoreMetadata: metadata)
    }
}

private extension CoreDataMigrationVersion {

    // MARK: - Compatible

    static func compatibleVersionForStoreMetadata(_ metadata: [String: Any], _ bundle: Bundle) -> CoreDataMigrationVersion? {
        let compatibleVersion = CoreDataMigrationVersion.allCases.first {
            let model = NSManagedObjectModel.managedObjectModel(forResource: $0.rawValue, inBundle: bundle)

            return model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
        }

        return compatibleVersion
    }
}
