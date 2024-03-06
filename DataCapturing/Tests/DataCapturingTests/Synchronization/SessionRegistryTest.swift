//
//  File.swift
//  
//
//  Created by Klemens Muthmann on 01.03.24.
//

import XCTest
import CoreData
@testable import DataCapturing

class SessionRegistryTest: XCTestCase {
    private var coreDataStack: CoreDataStack!

    open override func setUp() async throws{
        print("setting up")
        try await super.setUp()

        coreDataStack = try CoreDataStack()
        try await coreDataStack.setup()
    }

    override func tearDown() async throws {
        print("tearing down")
        try coreDataStack.wrapInContext { context in
            try context.persistentStoreCoordinator?.managedObjectModel.entities.forEach { entity in
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entity.name!)
                let batchDelete = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                try context.execute(batchDelete)
            }
        }
        coreDataStack = nil

        try await super.tearDown()
    }

    func testSessionRegistrySerialization() async throws {
        try coreDataStack.wrapInContext { context in
            let session = UploadSession(context: context)
            let measurement = MeasurementMO(context: context)
            measurement.time = Date()
            session.time = Date()
            session.measurement = measurement

            try context.save()
        }
    }

    /// Test that storing and loading a session works as expected.
    func testPersistentRegistryHappyPath() async throws {
        // Arrange
        let uploadFactory = MockUploadFactory()
        var oocut = PersistentSessionRegistry(dataStoreStack: coreDataStack, uploadFactory: uploadFactory)
        let mockMeasurement = FinishedMeasurement(identifier: 0)
        try coreDataStack.wrapInContext { context in
            let measurement = MeasurementMO(context: context)
            measurement.time = Date()
            measurement.identifier = Int64(mockMeasurement.identifier)

            try context.save()
        }
        let mockUpload = MockUpload(measurement: mockMeasurement)

        // Act
        try oocut.register(upload: mockUpload)

        // Assert
        XCTAssertEqual(mockUpload, try oocut.get(measurement: mockUpload.measurement) as? MockUpload)
    }
}
