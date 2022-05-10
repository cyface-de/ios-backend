/*
* Copyright 2019 - 2022 Cyface GmbH
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

import XCTest
import Foundation
import CoreData
@testable import DataCapturing

/**
Tests that reading and writing files works as expected.

 - Author: Klemens Muthmann
 - Version: 1.0.2
 - Since: 6.0.0
 */
class FileSupportTest: XCTestCase {
    static let dataModel = try! CoreDataManager.load()

    /// Tests that writing an events file works without further interruption.
    func testEventFileWriting_HappyPath() throws {
        // Arrange
        let oocut = EventsFile()
        let expectation = self.expectation(description: "Test completed after CoreData was initialized!")

        do {
            let coreDataStack = CoreDataManager(storeType: NSInMemoryStoreType, migrator: CoreDataMigrator(), modelName: "CyfaceModel", model: FileSupportTest.dataModel)
            let bundle = Bundle(for: type(of: coreDataStack))
            try coreDataStack.setup(bundle: bundle) { [weak self] (error) in
                if let error = error {
                    XCTFail("Unable to setup CoreData stack due to \(error).")
                }

                guard let self = self else {
                    return
                }

                do {
                    let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
                    let events = try self.eventFixture(persistenceLayer)

                    // Act
                    let eventsFilePath = try oocut.write(serializable: events, to: 1)

                    // Assert
                    print(eventsFilePath)
                    expectation.fulfill()
                } catch {
                    XCTFail("Unable to write serializable data.")
                }
            }
        } catch {
            XCTFail("Unable to setup CoreData stack due to \(error)")
        }
        
        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail("Writing event file timed out. \(error)")
            }
        }
    }

    /// The fixture of events to use for testing.
    func eventFixture(_ persistenceLayer: PersistenceLayer) throws -> [Event] {
        var measurement = try persistenceLayer.createMeasurement(at: DataCapturingService.convertToUtcTimestamp(date: Date()), inMode: "BICYCLE")
        let event1 = try persistenceLayer.createEvent(of: .lifecycleStart, parent: &measurement)
        let event2 = try persistenceLayer.createEvent(of: .modalityTypeChange, withValue: "BICYCLE", parent: &measurement)
        let event3 = try persistenceLayer.createEvent(of: .lifecycleStop, parent: &measurement)

        return [event1, event2, event3]
    }
}
