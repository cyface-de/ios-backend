/*
 * Copyright 2019 Cyface GmbH
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
 A class for objects representing a *CoreData* stack.
 Please call `setup(bundle:)` before using an object of this class.
 That call will run data migration if necessary and might take some time depending on the amount of data that must be migrated.
 So it might be a good idea to run `setup(bundle:)` on a background thread.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 4.0.0
 - Attention: Do not load or save any data before the call to `setup(bundle:)` has finished.
 */
public class CoreDataManager {

    /// An object to migrate between different Cyface model versions.
    let migrator: CoreDataMigratorProtocol
    /// The type of the store to use. In production this should usually be `NSSQLiteStoreType`. In a test environment you might use `NSInMemoryStoreType`. Both values are defined by *CoreData*.
    private let storeType: String

    /// The `NSPersistentContainer` used by this *CoreData* stack.
    lazy var persistentContainer: NSPersistentContainer = {
        let momdName = "CyfaceModel"
        let bundle = Bundle(for: type(of: self))
        guard let modelURL = bundle.url(forResource: momdName, withExtension: "momd") else {
            fatalError("Unable to access CoreData model \(momdName)!")
        }

        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Unable to load managed object model from URL: \(modelURL)!")
        }

        let persistentContainer = NSPersistentContainer(name: momdName, managedObjectModel: mom)
        let description = persistentContainer.persistentStoreDescriptions.first
        description?.shouldInferMappingModelAutomatically = false
        description?.shouldMigrateStoreAutomatically = false
        description?.type = storeType

        return persistentContainer
    }()

    /// Provides a background context usable on a background thread and accessing the data store managed by this stack.
    lazy var backgroundContext: NSManagedObjectContext = {
        let context = self.persistentContainer.newBackgroundContext()
        //context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        return context
    }()

    /// Provides a *CoreData* `NSManagedObjectContext` for the main thread, accessing the data store managed by this stack.
    lazy var mainContext: NSManagedObjectContext = {
        let context = self.persistentContainer.viewContext
        context.automaticallyMergesChangesFromParent = true

        return context
    }()

    // MARK: - Init

    /**
     Creates a new instance of the `CoreDataManager`.

     - Attention: Please call `setup(bundle:)` before using the `NSManagedObjectContext` instances, provided by this instance.
     - Parameters:
     - storeType: The type of the store to use. In production this should usually be `NSSQLiteStoreType`. In a test environment you might use `NSInMemoryStoreType`. Both values are defined by *CoreData*.
     - migrator: An object to migrate between different Cyface model versions.
     */
    public init(storeType: String = NSSQLiteStoreType, migrator: CoreDataMigratorProtocol = CoreDataMigrator()) {
        self.storeType = storeType
        self.migrator = migrator
    }

    // MARK: - SetUp

    /**
     Connects this `CoreDataManager` to the underlying storage, possibly migrating the data model to the current version.

     - Parameter bundle: The bundle containing the data model.
     */
    public func setup(bundle: Bundle) {
        migrateStoreIfNeeded(bundle: bundle)
        self.persistentContainer.loadPersistentStores { _, error in
            guard error == nil else {
                fatalError("Was unable to load store \(error.debugDescription).")
            }
        }
    }

    // MARK: - Loading

    /**
     Migrates the storage to the current version if required.

     - Parameter bundle: The bundle containing data and mapping models.
     */
    private func migrateStoreIfNeeded(bundle: Bundle) {
        guard let storeURL = persistentContainer.persistentStoreDescriptions.first?.url else {
            fatalError("PersistentContainer was not set up properly.")
        }

        if migrator.requiresMigration(at: storeURL, toVersion: CoreDataMigrationVersion.current, inBundle: bundle) {
            migrator.migrateStore(at: storeURL, toVersion: CoreDataMigrationVersion.current, inBundle: bundle)
        }
    }
}
