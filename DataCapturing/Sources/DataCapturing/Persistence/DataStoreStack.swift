/*
 * Copyright 2019 - 2024 Cyface GmbH
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

import CoreData
import OSLog

/**
 Protocol for objects talking to a data storage.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 12.0.0
 */
public protocol DataStoreStack {
    // TODO: The following two methods are not really an abstraction, as they provide an `NSManagedObjectContext`. This should be handled differently.
    /// All the code carried out inside the provided block can use the provided `NSManagedObjectContext` and be sure, that this context is valid at that time.
    ///
    /// This is the version of the method that returns nothing.
    /// It may be used to store away data.
    /// The block is executed synchronously and thus requires no handling of multi threading.
    /// Everything called after this call is also executed after this call.
    func wrapInContext(_ block: (NSManagedObjectContext) throws -> Void) throws
    /// This is a version of ``DataStoreStack/wrapInContext(_:)`` that returns a generic value.
    ///
    /// This method should be used to load data from storage or return status reports based on operations within the storage.
    func wrapInContextReturn<T>(_ block: (NSManagedObjectContext) throws -> T) throws -> T
    /// A method carrying out asynchronous initialization work.
    ///
    /// This method must be called shortly after initialization and before any other interaction with a newly created `DataStoreStack`.
    func setup() async throws
    /// This checks if a measurement with that identifier already exists and generates a new identifier until it finds one with no corresponding measurement.
    /// This is required to handle legacy data and installations, that still have measurements with falsely generated data.
    func nextValidIdentifier() throws -> UInt64
}

/**
 A class for objects representing a *CoreData* stack.

 Please call `setup(bundle:completionClosure:)` before using an object of this class.
 That call will run data migration if necessary and might take some time depending on the amount of data that must be migrated.
 So it might be a good idea to run `setup(bundle:completionClosure:)` on a background thread.

 - Author: Klemens Muthmann
 - Version: 4.0.0
 - Since: 4.0.0
 - Attention: You must call `setup(bundle:completionClosure:)` only once in your application. Usually this should happen in AddDelegate.application. Do not load or save any data before the call to `setup(bundle:completionClosure:)` has finished.
 */
public class CoreDataStack: DataStoreStack {
    /// An object to migrate between different Cyface model versions.
    let migrator: CoreDataMigratorProtocol
    /// The type of the store to use. In production this should usually be `NSSQLiteStoreType`. In a test environment you might use `NSInMemoryStoreType`. Both values are defined by *CoreData*.
    private let storeType: String
    private let bundle: Bundle
    /// The identifier that has been assigned the last to a new `Measurement`.
    private var lastIdentifier: UInt64?

    /// The `NSPersistentContainer` used by this *CoreData* stack.
    var persistentContainer: NSPersistentContainer

    /// Provides a background context usable on a background thread and accessing the data store managed by this stack.
    lazy var backgroundContext: NSManagedObjectContext = {
        let context = self.persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        // This improves performance as long as we do not need to undo on the background context.
        context.undoManager = nil

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

     - Attention: Please call `setup(bundle:completionClosure:)` before using the `NSManagedObjectContext` instances, provided by this instance.
     - Parameters:
       - storeType: The type of the store to use. In production this should usually be `NSSQLiteStoreType`. In a test environment you might use `NSInMemoryStoreType`. Both values are defined by *CoreData*.
       - migrator: An object to migrate between different Cyface model versions.
     - Throws: `CoreDataError.invalidModelUrl`, `CoreDataError.modelNotAvailable`
     */
    public convenience init(storeType: String = NSSQLiteStoreType, migrator: CoreDataMigratorProtocol = CoreDataMigrator()) throws {
        let bundle = Bundle.module
        let mom = try CoreDataStack.load(bundle: bundle)
        self.init(storeType: storeType, migrator: migrator, model: mom, bundle: bundle)
    }

    /// An initializer, mostly used by tests, to load a specific CoreData model.
    init(
        storeType: String = NSInMemoryStoreType,
        migrator: CoreDataMigratorProtocol = CoreDataMigrator(),
        modelName: String = "CyfaceModel",
        model: NSManagedObjectModel,
        bundle: Bundle
    ) {
        self.storeType = storeType
        self.migrator = migrator
        self.bundle = bundle

        // Initialize persistent container
        os_log("Creating persistent container", log: OSLog.persistence, type: .info)

        persistentContainer = NSPersistentContainer(name: modelName, managedObjectModel: model)
        let description = persistentContainer.persistentStoreDescriptions.first
        description?.shouldInferMappingModelAutomatically = false
        description?.shouldMigrateStoreAutomatically = false
        description?.type = storeType
    }

    // MARK: - SetUp
    public func setup() async throws {
        // TODO: Remove this parameter as soon as deprecated setup method has been deleted.
        try migrateStoreIfNeeded(bundle: self.bundle)
        typealias LoadPersistentStoreContinuation = CheckedContinuation<NSPersistentStoreDescription, Error>
        _ = try await withCheckedThrowingContinuation { (loadPersistentStoreContinuation: LoadPersistentStoreContinuation) in
            persistentContainer.loadPersistentStores { result, error in
                if let error = error {
                    loadPersistentStoreContinuation.resume(throwing: error)
                } else {
                    loadPersistentStoreContinuation.resume(returning: result)
                }
            }
        }
    }

    /// Load the specified `NSManagedObjectModel` from disk.
    public static func load(model: String = "CyfaceModel", bundle: Bundle) throws -> NSManagedObjectModel {
        guard let modelURL = bundle.url(forResource: model, withExtension: "momd") else {
            throw CoreDataError.invalidModelUrl(model)
        }

        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            throw CoreDataError.modelNotAvailable(modelURL)
        }

        return mom
    }

    // MARK: - Loading

    /**
     Migrates the storage to the current version if required.

     - Parameter bundle: The bundle containing data and mapping models.
     - Throws: `CoreDataError.missingModelUrl`
     */
    private func migrateStoreIfNeeded(bundle: Bundle) throws {
        // TODO: this loads the storeURL for the wrong location
        guard let storeURL = persistentContainer.persistentStoreDescriptions.first?.url else {
            throw CoreDataError.missingModelUrl
        }

        if try migrator.requiresMigration(at: storeURL, inBundle: bundle) {
            try migrator.migrateStore(at: storeURL, inBundle: bundle)
        }
    }

    /// The next identifier to assign to a new `Measurement`. This is no private since it is used by unit tests.
    private func nextIdentifier() throws -> UInt64 {
        let persistentStore = persistentContainer.persistentStoreCoordinator.persistentStores[0]
        let coordinator = persistentContainer.persistentStoreCoordinator

        if lastIdentifier == nil {
            // identifier is already stored as metadata.
            if let currentIdentifier = coordinator.metadata(for: persistentStore)["de.cyface.mid"] as? UInt64 {
                lastIdentifier = currentIdentifier
                // identifier is not yet stored, create an entry
            } else {
                lastIdentifier = UInt64(0)
                coordinator.setMetadata(["de.cyface.mid": lastIdentifier as Any], for: persistentStore)
            }
        }

        guard let lastIdentifier = lastIdentifier else {
            throw PersistenceError.inconsistentState
        }

        let nextIdentifier = lastIdentifier + 1
        self.lastIdentifier = nextIdentifier
        coordinator.setMetadata(["de.cyface.mid": nextIdentifier], for: persistentStore)
        return nextIdentifier
    }

    /**
     Wrap a block of data inside a valid `NSManagedObjectContext`. As long as control is not handed to any other thread, it is save to use managed objects within that block.

     - Throws: Any error thrown by the block is rethrown here.
     */
    public func wrapInContext(_ block: (NSManagedObjectContext) throws -> Void) throws {
        var outerError: Error?

        backgroundContext.performAndWait {
            do {
                try block(backgroundContext)
            } catch {
                outerError = error
            }
        }

        if let unwrappedError = outerError {
            throw unwrappedError
        }
    }

    /**
     Wrap a block of data inside a valid `NSMNagedObjectContext` and return some result. Similarly to `wrapInContext` it is save to use managed objects within this block as long as control is not transfered to another thread or queue.

     - Throws: Any error thrown by the block is rethrown here.
     */
    public func wrapInContextReturn<T>(_ block: (NSManagedObjectContext) throws -> T) throws -> T {
        var outerError: Error?
        var ret: T?

        backgroundContext.performAndWait {
            do {
                ret = try block(backgroundContext)
            } catch {
                outerError = error
            }
        }

        if let unwrappedError = outerError {
            throw unwrappedError
        } else if let ret = ret {
            return ret
        } else {
            fatalError()
        }
    }

    public func nextValidIdentifier() throws -> UInt64 {
        var fetchedMeasurements = [MeasurementMO]()
        var identifier = UInt64(0)
        repeat {
            identifier = try nextIdentifier()
            let fetchRequest = persistentContainer
                .managedObjectModel
                .fetchRequestFromTemplate(withName: "measurementByIdentifier", substitutionVariables: ["identifier": identifier])
            fetchedMeasurements = try fetchRequest?.execute() as? [MeasurementMO] ?? []
        } while !fetchedMeasurements.isEmpty
        return identifier
    }

    /**
        A collection of all the errors thrown by the `CoreDataManager`.

     - Author: Klemens Muthmann
     - Since: 10.0.0
     - Version: 1.0.0
     */
    enum CoreDataError: Error {
        /// If the URL to the CoreData model file can not be processed by the system. This should usually not happen, since it does not depend on user input. If you encounter this error you probably have an invalid build of the Cyface SDK.
        case invalidModelUrl(String)
        /// A CoreData persistent store was missing its model URL. This is not supposed to happen, unless you are starting data migration before initialization of the persistent store. Doing this is only possible if you are messing with the persistent store manually and circumventing Cyface interfaces.‚
        case missingModelUrl
        /// If the file containing the Cyface CoreData data model is not available. If you encounter this error, you probably have an invalid build of the Cyface SDK. The file should be under DataCapturing/Source/Model/CyfaceModel.xcdatamodeld.
        case modelNotAvailable(URL)
    }
}
