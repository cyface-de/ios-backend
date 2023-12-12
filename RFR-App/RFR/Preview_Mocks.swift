/*
 * Copyright 2023 Cyface GmbH
 *
 * This file is part of the Ready for Robots App.
 *
 * The Ready for Robots App is free software: you can redistribute it and/or modify
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
#if DEBUG
import Foundation
import DataCapturing
import CoreData
import OSLog

class MockAuthenticator: Authenticator {
    func authenticate(onSuccess: @escaping (String) -> Void, onFailure: @escaping (Error) -> Void) {
        onSuccess("fake-token")
    }

    func authenticate() async throws -> String {
        return "test"
    }

    func delete() async throws {
        print("Deleting User")
    }

    func logout() async throws {
         print("Logout")
    }

    func callback(url: URL) {
        print("Called back")
    }
}

class MockDataStoreStack: DataStoreStack {
    let mockPersistenceLayer: MockPersistenceLayer

    init(persistenceLayer: MockPersistenceLayer) {
        self.mockPersistenceLayer = persistenceLayer
    }

    func wrapInContextReturn<T>(_ block: (NSManagedObjectContext) throws -> T) throws -> T {
        return try block(NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType))
    }

    private var nextIdentifier = UInt64(0)

    func nextValidIdentifier() throws -> UInt64 {
        nextIdentifier += 1
        return nextIdentifier
    }

    func wrapInContext(_ block: (NSManagedObjectContext) throws -> Void) throws {

    }

    func setup() async throws {
        // Nothing to do here!
    }

    func persistenceLayer() -> DataCapturing.PersistenceLayer {
        return mockPersistenceLayer
    }
}

class MockPersistenceLayer: PersistenceLayer {

    var measurements = [FinishedMeasurement]()/*[
        DataCapturing.FinishedMeasurement(identifier: 0),
        DataCapturing.FinishedMeasurement(identifier: 1),
        DataCapturing.FinishedMeasurement(identifier: 2)
    ]*/

    init(measurements: [FinishedMeasurement]) {
        self.measurements.append(contentsOf: measurements)
    }

    func delete(measurement: UInt64) throws {

    }

    func delete(event: DataCapturing.Event) throws {

    }

    func delete() throws {
        
    }

    func clean(measurement: UInt64) throws {

    }

    func createMeasurement(at time: Date, inMode mode: String) throws -> DataCapturing.FinishedMeasurement {
        return DataCapturing.FinishedMeasurement(identifier: 0)
    }

    func createEvent(of type: DataCapturing.EventType, withValue: String?, time: Date, parent: inout DataCapturing.FinishedMeasurement) throws -> DataCapturing.Event {
        return DataCapturing.Event(type: .lifecycleStart)
    }

    func appendNewTrack(to measurement: inout DataCapturing.FinishedMeasurement) throws {

    }

    func save(measurement: DataCapturing.FinishedMeasurement) throws -> DataCapturing.FinishedMeasurement {
        return DataCapturing.FinishedMeasurement(identifier: 0)
    }

    func save(locations: [DataCapturing.GeoLocation], in measurement: inout DataCapturing.FinishedMeasurement) throws {

    }

    func save(accelerations: [DataCapturing.SensorValue], rotations: [DataCapturing.SensorValue], directions: [DataCapturing.SensorValue], in measurement: inout DataCapturing.Measurement) throws {

    }

    func load(measurementIdentifiedBy identifier: UInt64) throws -> DataCapturing.FinishedMeasurement {
        return DataCapturing.FinishedMeasurement(identifier: 0)
    }

    func loadMeasurements() throws -> [DataCapturing.FinishedMeasurement] {
        return [DataCapturing.FinishedMeasurement]()
    }

    func loadEvents(typed type: DataCapturing.EventType, forMeasurement measurement: DataCapturing.FinishedMeasurement) throws -> [DataCapturing.Event] {
        return [DataCapturing.Event]()
    }

    func loadSynchronizableMeasurements() throws -> [DataCapturing.FinishedMeasurement] {
        return measurements.filter { $0.synchronizable}
    }

    func loadClean(track: inout DataCapturing.Track) throws -> [DataCapturing.GeoLocation] {
        return [DataCapturing.GeoLocation]()
    }

    func countGeoLocations(forMeasurement measurement: DataCapturing.FinishedMeasurement) throws -> Int {
        return 0
    }
}

#endif
