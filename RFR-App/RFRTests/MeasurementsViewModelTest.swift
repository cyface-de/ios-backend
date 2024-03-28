/*
 * Copyright 2024 Cyface GmbH
 *
 * This file is part of the Ready for Robots iOS App.
 *
 * The Ready for Robots iOS App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Ready for Robots iOS App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Ready for Robots iOS App. If not, see <http://www.gnu.org/licenses/>.
 */

import XCTest
import DataCapturing
import CoreData
@testable import Ready_for_Robots_Development

/**
Test calls to the ``MeasurementsViewModel``.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
final class MeasurementsViewModelTest: XCTestCase {

    /// Test if setting up a ``MeasurementsViewModel`` works as expected.
    func test() async throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.

        // Arrange
        let dataStoreStack = try CoreDataStack(storeType: NSInMemoryStoreType)
        try await dataStoreStack.setup()
        let measurement01Time = Date(timeIntervalSince1970: 1711621663)
        let measurement02Time = Date(timeIntervalSince1970: 1711621699)

        try dataStoreStack.wrapInContext { context in
            var measurement01 = MeasurementMO(context: context)
            measurement01.identifier = 0
            measurement01.synchronizable = true
            measurement01.synchronized = false
            measurement01.time = measurement01Time

            var measurement02 = MeasurementMO(context: context)
            measurement02.identifier = 1
            measurement02.synchronizable = true
            measurement02.synchronized = false
            measurement02.time = measurement02Time

            try context.save()
        }

        let oocut = MeasurementsViewModel(dataStoreStack: dataStoreStack)

        // Act
        try await oocut.setup()

        // Assert
        XCTAssertFalse(oocut.isLoading)
        XCTAssertEqual(oocut.measurements.count, 2)
    }
}
