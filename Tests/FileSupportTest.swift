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

import XCTest
import Foundation
import CoreData
@testable import DataCapturing

/**
 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 6.0.0
 */
class FileSupportTest: XCTestCase {

    /// Tests that writing an events file works without further interruption.
    func testEventFileWriting_HappyPath() throws {
        // Arrange
        let oocut = EventsFile()

        let coreDataStack = CoreDataManager(storeType: NSInMemoryStoreType, migrator: CoreDataMigrator())
        let bundle = Bundle(for: type(of: coreDataStack))
        coreDataStack.setup(bundle: bundle)

        let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
        let context = persistenceLayer.makeContext()
        persistenceLayer.context = context

        let events = eventFixture(context)

        // Act
        let eventsFilePath = try oocut.write(serializable: events, to: 1)

        // Assert
        print(eventsFilePath)
    }

    /// The fixture of events to use for testing.
    func eventFixture(_ context: NSManagedObjectContext) -> [Event] {
        let event1 = Event(context: context)
        let event2 = Event(context: context)
        let event3 = Event(context: context)
        let measurement = MeasurementMO(context: context)
        event1.measurement = measurement
        event2.measurement = measurement
        event3.measurement = measurement
        event1.time = NSDate()
        event2.time = NSDate()
        event3.time = NSDate()
        event1.typeEnum = .lifecycleStart
        event2.typeEnum = .modalityTypeChange
        event3.typeEnum = .lifecycleStop
        event2.value = "BICYCLE"
        measurement.addToEvents(event1)
        measurement.addToEvents(event2)
        measurement.addToEvents(event3)

        context.saveRecursively()

        return [event1, event2, event3]
    }
}
