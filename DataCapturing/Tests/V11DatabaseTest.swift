/*
 * Copyright 2023 Cyface GmbH
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
import CoreMotion
import XCTest
@testable import DataCapturing

/**
 Test that the database used to store the version 11 data, works correctly.

 - author: Klemens Muthmann
 */
class V11DatabaseTest: XCTestCase {

    /// A *CoreData* stack to test with.
    private var v11Stack: CoreDataManager!

    /// Setting up the in memory database used for testing.
    override func setUp() {
        do {
            let model = try CoreDataManager.load(model: "v11model")
            let migrator = CoreDataMigrator(model: "v11model", to: CoreDataMigrationVersion.v11version9)
            let v11Stack = CoreDataManager(storeType: NSInMemoryStoreType, migrator: migrator, modelName: "v11model", model: model)
            let expectation = expectation(description: "Wait for CoreData Stack to finish!")
            try v11Stack.setup(bundle: Bundle(for: CoreDataManager.self)) { error in
                if let error = error {
                    XCTFail(error.localizedDescription)
                }
                expectation.fulfill()
            }
            self.v11Stack = v11Stack
        } catch {
            XCTFail("\(error)")
        }

        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail(error.localizedDescription)
            }
        }
    }

    /// Reset everything for the next test.
    override func tearDown() {
        v11Stack = nil
    }

    /// Test that it works to calculate the accumulated altitude only from geo location data.
    func testCalculateSummedAltitudeWithoutAltimeter() throws {
        // Arrange
        let measurement = Measurement(identifier: 0)
        measurement.append(track: Track(parent: measurement))
        try v11Stack.wrapInContext { context in
            let measurementV11 = MeasurementV11(context: context)
            measurementV11.identifier = measurement.identifier
            measurementV11.addToTracks(TrackV11(context: context))
            let track = measurementV11.lastTrack()

            fixtureLocations(context: context, track: track)

            try context.save()
        }
        let oocut = V11Database(coreDataStack: v11Stack)

        // Act
        let calculatedSum = try oocut.summedHeight(measurement: measurement)

        // Assert
        XCTAssertEqual(calculatedSum, 13.0)
    }

    /// Test a typical happy path calculation of the accumulated altitude of a single `Measurement`.
    func testCalculateSummedAltitudeHappyPath() throws {
        // Arrange
        let measurement = Measurement(identifier: 0)
        try v11Stack.wrapInContext { context in
            let measurement = MeasurementV11(context: context)
            measurement.identifier = 0

            let track = TrackV11(context: context)
            measurement.addToTracks(track)

            fixtureLocations(context: context, track: track)
            fixtureAltitudes(context: context, track: track)

            try context.save()
        }
        let oocut = V11Database(coreDataStack: v11Stack)

        // Act
        let calculatedSum = try oocut.summedHeight(measurement: measurement)

        // Assert
        XCTAssertEqual(calculatedSum, 15.5, accuracy: 0.1)
    }

    /// Test that calculating the accumulated altitude does not crash if no altitude data is available.
    func testCalculateSummedAltitudeWithNoAltitudeData() throws {
        // Arrange
        let measurement = Measurement(identifier: 0)
        try v11Stack.wrapInContext { context in
            let measurement = MeasurementV11(context: context)
            measurement.identifier = 0

            let track = TrackV11(context: context)
            measurement.addToTracks(track)

            try context.save()
        }
        let oocut = V11Database(coreDataStack: v11Stack)

        // Act
        let calculatedSum = try oocut.summedHeight(measurement: measurement)

        // Assert
        XCTAssertEqual(calculatedSum, 0.0)
    }

    /// Test that very small changes, which can be attributed to sensor noise, are not added to the summed altitude.
    func testCalculateSummedAltitudeWithNoiseChanges() throws {
        // Arrange
        let measurement = Measurement(identifier: 0)
        try v11Stack.wrapInContext { context in
            let measurement = MeasurementV11(context: context)
            measurement.identifier = 0

            let track = TrackV11(context: context)
            measurement.addToTracks(track)

            fixtureLocations(context: context, track: track)
            let noisyLocation01 = GeoLocationWithAltitudeMO(context: context)
            noisyLocation01.timestamp = 1673952114087
            noisyLocation01.altitude = 29.0
            noisyLocation01.verticalAccuracy = 2.3
            noisyLocation01.speed = 5.0
            noisyLocation01.accuracy = 2.7
            noisyLocation01.isPartOfCleanedTrack = true
            noisyLocation01.lat = 13.706346
            noisyLocation01.lon = 51.051170
            track.addToLocations(noisyLocation01)

            let noisyLocation02 = GeoLocationWithAltitudeMO(context: context)
            noisyLocation02.timestamp = 1673952115087
            noisyLocation02.altitude = 28.5
            noisyLocation02.verticalAccuracy = 12.3
            noisyLocation02.speed = 4.8
            noisyLocation02.accuracy = 2.5
            noisyLocation02.isPartOfCleanedTrack = true
            noisyLocation02.lat = 13.706356
            noisyLocation02.lon = 51.051172
            track.addToLocations(noisyLocation02)

            try context.save()
        }
        let oocut = V11Database(coreDataStack: v11Stack)

        // Act
        let calculatedSum = try oocut.summedHeight(measurement: measurement)

        // Assert
        XCTAssertEqual(calculatedSum, 13.0)

    }

    /// Test that calculating the summed altitude works, even if the track was paused in between. In such instances the height achieved during
    /// the pause should not be included in the sum.
    func testCalculateSummedAltitudeWithPausedMeasurement() throws {
        // Arrange
        let measurement = Measurement(identifier: 0)
        try v11Stack.wrapInContext { context in
            let measurement = MeasurementV11(context: context)
            measurement.identifier = 0

            let track01 = TrackV11(context: context)
            measurement.addToTracks(track01)

            let track02 = TrackV11(context: context)
            measurement.addToTracks(track02)

            fixtureLocations(context: context, track: track01)
            fixtureLocations(context: context, track: track02)
            fixtureAltitudes(context: context, track: track01)
            fixtureAltitudes(context: context, track: track02)
        }
        let oocut = V11Database(coreDataStack: v11Stack)

        // Act
        let calculatedSum = try oocut.summedHeight(measurement: measurement)

        // Assert
        XCTAssertEqual(calculatedSum, 31.0, accuracy: 0.1)
    }

    /// Happy path test for storing some `GeoLocationWithAltitude` instances.
    func testStoreGeoLocationsWithAltitude() throws {
        // Arrange
        let measurement = Measurement(identifier: 0)
        let oocut = V11Database(coreDataStack: v11Stack)

        let locationsCache = fixtureLocationCache()

        // Act
        try oocut.store(locations: locationsCache, to: measurement)

        // Assert
        try v11Stack.wrapInContext { context in
            let v11Measurement = try MeasurementV11.load(measurement: measurement, context: context)
            let storedLocations = v11Measurement.typedTracks()[0].typedLocations()
            XCTAssertEqual(storedLocations.count, 2)
            XCTAssertEqual(storedLocations[0].timestamp, Int64(locationsCache[0].timestamp.timeIntervalSince1970*1000.0))
            XCTAssertEqual(storedLocations[1].timestamp, Int64(locationsCache[1].timestamp.timeIntervalSince1970*1000.0))
        }
    }

    /// Test that storing `GeoLocationWithAltitude` does not crash, even if no data is provided.
    func testStoreGeoLocationsWithAltitudeWhenNoDataIsAvailable() throws {
        // Arrange
        let oocut = V11Database(coreDataStack: v11Stack)
        let measurement = Measurement(identifier: 0)

        // Act
        try oocut.store(locations: [], to: measurement)

        // Assert
        try v11Stack.wrapInContext { context in
            let v11Measurement = try MeasurementV11.load(measurement: measurement, context: context)
            let storedLocations = v11Measurement.typedTracks()[0].typedLocations()
            XCTAssertTrue(storedLocations.isEmpty)

        }
    }

    /// Happy path test for storing some altimeter altitudes.
    func testStoreAltitudes() throws {
        // Arrange
        let measurement = Measurement(identifier: 0)
        let track = Track(parent: measurement)
        measurement.append(track: track)

        let oocut = V11Database(coreDataStack: v11Stack)
        let altitudeCache = fixtureAltitudeCache()

        // Act
        try oocut.store(altitudes: altitudeCache, to: measurement)

        // Assert
        try v11Stack.wrapInContext { context in
            let v11Measurement = try MeasurementV11.load(measurement: measurement, context: context)

            XCTAssertEqual(v11Measurement.typedTracks().count, 1)
            XCTAssertEqual(v11Measurement.typedTracks()[0].typedAltitudes().count, 2)
            XCTAssertEqual(v11Measurement.typedTracks()[0].typedAltitudes()[0].timestamp, altitudeCache[0].timestamp)
            XCTAssertEqual(v11Measurement.typedTracks()[0].typedAltitudes()[1].timestamp, altitudeCache[1].timestamp)
        }

    }

    /// Altitudes are stored correctly even if no data is provided. The application should not crash under these circumstances.
    func testStoreAltitudesWhenNoDataIsAvailable() throws {
        // Arrange
        let measurement = Measurement(identifier: 0)
        let track = Track(parent: measurement)
        measurement.append(track: track)

        let oocut = V11Database(coreDataStack: v11Stack)

        // Act
        try oocut.store(altitudes: [], to: measurement)

        // Assert
        try v11Stack.wrapInContext { context in
            let v11Measurement = try MeasurementV11.load(measurement: measurement, context: context)
            XCTAssertEqual(v11Measurement.typedTracks().count, 1)
            XCTAssertTrue(v11Measurement.typedTracks()[0].typedAltitudes().isEmpty)
        }
    }

    /// Tests for RaceConditions while storing data to the database.
    func testChaosStore() {
        // Arrange
        let group = DispatchGroup()
        let measurement = Measurement(identifier: 0)
        let oocut = V11Database(coreDataStack: v11Stack)

        for _ in 0...1000 {
            group.enter()

            DispatchQueue.global().async {
                let sleepVal = arc4random() % 1000
                usleep(sleepVal)
                if Bool.random() {
                    do {
                        try oocut.store(altitudes: self.fixtureAltitudeCache(), to: measurement)
                    } catch {
                        XCTFail(error.localizedDescription)
                    }
                } else {
                    do {
                        try oocut.store(locations: self.fixtureLocationCache(), to: measurement)
                    } catch {
                        XCTFail(error.localizedDescription)
                    }
                }
                group.leave()
            }
        }

        let result = group.wait(timeout: DispatchTime.now() + 10)

        XCTAssert(result == .success)
    }


    /// Test that migration does not crash on V11 model but also is not executed, since no migration is necessary.
    func testDataMigration() throws {
        let model = try CoreDataManager.load(model: "v11model")
        let migrator = CoreDataMigrator(model: "v11model", to: CoreDataMigrationVersion.v11version9)
        let bundle = Bundle(for: CoreDataManager.self)
        let newV11Stack = CoreDataManager(storeType: NSInMemoryStoreType, migrator: migrator, modelName: "v11model", model: model)

        try newV11Stack.setup(bundle: bundle) { error in
            if let error = error {
                XCTFail(error.localizedDescription)
            }
        }

        guard let persistentStoreUrl = newV11Stack.persistentContainer.persistentStoreDescriptions.first?.url else {
            XCTFail()
            return
        }
        XCTAssertFalse(try migrator.requiresMigration(at: persistentStoreUrl, inBundle: bundle))
    }

    /// Add a fixture of locations to the test database.
    private func fixtureLocations(context: NSManagedObjectContext, track: TrackV11) {
        let location01 = GeoLocationWithAltitudeMO(context: context)
        let location02 = GeoLocationWithAltitudeMO(context: context)
        let location03 = GeoLocationWithAltitudeMO(context: context)
        let location04 = GeoLocationWithAltitudeMO(context: context)
        let location05 = GeoLocationWithAltitudeMO(context: context)

        location01.altitude = 20.0
        location01.verticalAccuracy = 5.0
        location01.speed = 5.0
        location01.timestamp = 1673952109087
        location01.accuracy = 3.0
        location01.isPartOfCleanedTrack = true
        location01.lat = 13.706345
        location01.lon = 51.051180
        track.addToLocations(location01)

        location02.altitude = 24.0
        location02.verticalAccuracy = 3.0
        location02.speed = 4.3
        location02.timestamp = 1673952110087
        location02.accuracy = 3.1
        location02.isPartOfCleanedTrack = false
        location02.lat = 13.706350
        location02.lon = 51.051185
        track.addToLocations(location02)

        location03.altitude = 30.0
        location03.verticalAccuracy = 2.7
        location03.speed = 4.7
        location03.timestamp = 1673952111087
        location03.accuracy = 2.9
        location03.isPartOfCleanedTrack = true
        location03.lat = 13.706351
        location03.lon = 51.051183
        track.addToLocations(location03)

        location04.altitude = 25.0
        location04.verticalAccuracy = 2.3
        location04.speed = 4.9
        location04.timestamp = 1673952112087
        location04.accuracy = 2.0
        location04.isPartOfCleanedTrack = true
        location04.lat = 13.706352
        location04.lon = 51.051180
        track.addToLocations(location04)

        location05.altitude = 28.0
        location05.verticalAccuracy = 2.5
        location05.speed = 5.1
        location05.timestamp = 1673952113087
        location05.accuracy = 2.5
        location05.isPartOfCleanedTrack = true
        location05.lat = 13.706345
        location05.lon = 51.051170
        track.addToLocations(location05)
    }

    /// Add a fixture of altitudes to the test database.
    private func fixtureAltitudes(context: NSManagedObjectContext, track: TrackV11) {
        let altitude01 = AltitudeMO(context: context)
        let altitude02 = AltitudeMO(context: context)
        let altitude03 = AltitudeMO(context: context)
        let altitude04 = AltitudeMO(context: context)
        let altitude05 = AltitudeMO(context: context)

        altitude01.altitude = 0.0
        altitude01.timestamp = Date(timeIntervalSince1970: 1673952109.087)
        track.addToAltitudes(altitude01)

        altitude02.altitude = 5.0
        altitude02.timestamp = Date(timeIntervalSince1970: 1673952110.087)
        track.addToAltitudes(altitude02)

        altitude03.altitude = 7.0
        altitude03.timestamp = Date(timeIntervalSince1970: 1673952111.087)
        track.addToAltitudes(altitude03)

        altitude04.altitude = -6.0
        altitude04.timestamp = Date(timeIntervalSince1970: 1673952112.087)
        track.addToAltitudes(altitude04)

        altitude05.altitude = 4.0
        altitude05.timestamp = Date(timeIntervalSince1970: 1673952113.087)
        track.addToAltitudes(altitude05)
    }

    /// Fixture of an altitude cache used by these tests to simulate the real thing.
    private func fixtureAltitudeCache() -> [Altitude] {
        let altitude01 = Altitude(relativeAltitude: 0.0, pressure: 1013.0, timestamp: Date(timeIntervalSince1970: 1673952109.087))
        let altitude02 = Altitude(relativeAltitude: 5.0, pressure: 1013.0, timestamp: Date(timeIntervalSince1970: 1673952110.087))

        return [altitude01, altitude02]
    }

    /// Fixture of a location cache used by these tests to simulate the real thing.
    private func fixtureLocationCache() -> [LocationCacheEntry] {
        let location01 = LocationCacheEntry(latitude: 13.706345, longitude: 51.051180, altitude: 20.0, accuracy: 3.0, verticalAccuracy: 5.0, speed: 5.0, timestamp: Date(timeIntervalSince1970: 1673952109.087), isValid: true)
        let location02 = LocationCacheEntry(latitude: 13.706350, longitude: 51.051185, altitude: 24.0, accuracy: 3.1, verticalAccuracy: 3.0, speed: 4.3, timestamp: Date(timeIntervalSince1970: 1673952110.087), isValid: false)

        return [location01, location02]
    }
}
