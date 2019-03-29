//
//  CoreDataManager.swift
//  DataCapturing
//
//  Created by Team Cyface on 28.03.19.
//  Copyright © 2019 Cyface GmbH. All rights reserved.
//

import Foundation
import CoreData

public class CoreDataManager {

    let migrator: CoreDataMigratorProtocol
    private let storeType: String

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

    lazy var backgroundContext: NSManagedObjectContext = {
        let context = self.persistentContainer.newBackgroundContext()
        //context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        return context
    }()

    lazy var mainContext: NSManagedObjectContext = {
        let context = self.persistentContainer.viewContext
        context.automaticallyMergesChangesFromParent = true

        return context
    }()

    // MARK: - Init

    init(storeType: String = NSSQLiteStoreType, migrator: CoreDataMigratorProtocol = CoreDataMigrator()) {
        self.storeType = storeType
        self.migrator = migrator
    }

    // MARK: - SetUp

    public func setup(bundle: Bundle) {
        loadPersistentStore(bundle: bundle)
    }

    // MARK: - Loading

    private func loadPersistentStore(bundle: Bundle) {
        migrateStoreIfNeeded(bundle: bundle)
            self.persistentContainer.loadPersistentStores { _, error in
                guard error == nil else {
                    fatalError("Was unable to load store \(error.debugDescription).")
                }
            }
    }

    private func migrateStoreIfNeeded(bundle: Bundle) {
        guard let storeURL = persistentContainer.persistentStoreDescriptions.first?.url else {
            fatalError("PersistentContainer was not set up properly.")
        }

        if migrator.requiresMigration(at: storeURL, toVersion: CoreDataMigrationVersion.current, inBundle: bundle) {
                migrator.migrateStore(at: storeURL, toVersion: CoreDataMigrationVersion.current, inBundle: bundle)
            }
        }
}
