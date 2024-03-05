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
    func testSessionRegistrySerialization() async throws {
        let coreDataStack = try CoreDataStack()
        try await coreDataStack.setup()
        try coreDataStack.wrapInContext { context in
            /*let session = UploadSession(context: context)
            session.time = Date()
            session.identifier = 0

            try context.save()*/
        }
    }

    /// Test that storing and loading a session works as expected.
    func testPersistentRegistryHappyPath() throws {
        // Arrange
        let coreDataStack = try CoreDataStack()
        let uploadFactory = MockUploadFactory()
        var oocut = PersistentSessionRegistry(dataStoreStack: coreDataStack, uploadFactory: uploadFactory)
        let mockMeasurement = FinishedMeasurement(identifier: 0)
        let mockUpload = MockUpload(measurement: mockMeasurement)

        // Act
        try oocut.register(upload: mockUpload)

        // Assert
        XCTAssertEqual(mockUpload, try oocut.get(measurement: mockUpload.measurement) as? MockUpload)
    }
}
