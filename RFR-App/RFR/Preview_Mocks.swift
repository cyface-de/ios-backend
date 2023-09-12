//
//  Preview_Mocks.swift
//  RFR
//
//  Created by Klemens Muthmann on 03.04.23.
//
#if DEBUG
import Foundation
import DataCapturing
import CoreData
import OSLog

class MockAuthenticator: Authenticator {
    func authenticate(onSuccess: @escaping (String) -> Void, onFailure: @escaping (Error) -> Void) {
        fatalError("Not implemented")
    }


    func authenticate() async throws -> String {
        return "test"
    }
}

class MockDataStoreStack: DataStoreStack {
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
        return MockPersistenceLayer()
    }
}

class MockPersistenceLayer: PersistenceLayer {



    let measurements = [
        DataCapturing.FinishedMeasurement(identifier: 0),
        DataCapturing.FinishedMeasurement(identifier: 1),
        DataCapturing.FinishedMeasurement(identifier: 2)
    ]

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
        return [DataCapturing.FinishedMeasurement]()
    }

    func loadClean(track: inout DataCapturing.Track) throws -> [DataCapturing.GeoLocation] {
        return [DataCapturing.GeoLocation]()
    }

    func countGeoLocations(forMeasurement measurement: DataCapturing.FinishedMeasurement) throws -> Int {
        return 0
    }
}

#endif
