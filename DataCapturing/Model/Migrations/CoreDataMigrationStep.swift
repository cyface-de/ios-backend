//
//  CoreDataMigrationStep.swift
//  DataCapturing
//
//  Created by Team Cyface on 27.03.19.
//  Copyright © 2019 Cyface GmbH. All rights reserved.
//

import Foundation
import CoreData

struct CoreDataMigrationStep {
    let sourceModel: NSManagedObjectModel
    let destinationModel: NSManagedObjectModel
    let mappingModel: NSMappingModel

    // MARK: - Initializers

    init(sourceVersion: CoreDataMigrationVersion, destinationVersion: CoreDataMigrationVersion, bundle: Bundle) {
        let sourceModel = NSManagedObjectModel.managedObjectModel(forResource: sourceVersion.rawValue, inBundle: bundle)
        let destinationModel = NSManagedObjectModel.managedObjectModel(forResource: destinationVersion.rawValue, inBundle: bundle)

        guard let mappingModel = CoreDataMigrationStep.mappingModel(fromSourceModel: sourceModel, toDestinationModel: destinationModel, inBundle: bundle) else {
            fatalError("Expected model mapping not present")
        }

        self.sourceModel = sourceModel
        self.destinationModel = destinationModel
        self.mappingModel = mappingModel
    }

    // MARK: - Methods

    private static func mappingModel(fromSourceModel sourceModel: NSManagedObjectModel, toDestinationModel destinationModel: NSManagedObjectModel, inBundle bundle: Bundle) -> NSMappingModel? {
        guard let customMapping = customMappingModel(fromSourceModel: sourceModel, toDestinationModel: destinationModel, inBundle: bundle) else {
            return inferredMappingModel(fromSourceModel: sourceModel, toDestinationModel: destinationModel)
        }

        return customMapping
    }

    private static func inferredMappingModel(fromSourceModel sourceModel: NSManagedObjectModel, toDestinationModel destinationModel: NSManagedObjectModel) -> NSMappingModel? {
        return try? NSMappingModel.inferredMappingModel(forSourceModel: sourceModel, destinationModel: destinationModel)
    }

    private static func customMappingModel(fromSourceModel sourceModel: NSManagedObjectModel, toDestinationModel destinationModel: NSManagedObjectModel, inBundle bundle: Bundle) -> NSMappingModel? {
        return NSMappingModel(from: [bundle], forSourceModel: sourceModel, destinationModel: destinationModel)
    }
}
