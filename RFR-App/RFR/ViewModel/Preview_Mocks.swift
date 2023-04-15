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

class MockDataCapturingService: DataCapturingService {

    let dataStoreStack: DataStoreStack = MockDataStoreStack()

    var isRunning: Bool

    var isPaused: Bool

    var currentMeasurement: Int64?

    var capturedMeasurement: DataCapturing.Measurement?

    var handler: [((DataCapturing.DataCapturingEvent, DataCapturing.Status) -> Void)]

    init(state: MeasurementState) {
        self.currentMeasurement = nil
        self.capturedMeasurement = nil
        self.handler = [((DataCapturing.DataCapturingEvent, DataCapturing.Status) -> Void)]()

        switch state {
        case .paused:
            isRunning = false
            isPaused = true
        case .running:
            isRunning = true
            isPaused = false
        case .stopped:
            isRunning = false
            isPaused = false
        }
    }

    func setup() {

    }

    func start(inMode modality: String) throws {

    }

    func stop() throws {

    }

    func pause() throws {

    }

    func resume() throws {

    }

    func changeModality(to modality: String) {

    }
}

class MockAuthenticator: CredentialsAuthenticator {
    var username: String?

    var password: String?

    var authenticationEndpoint: URL

    init() {
        self.username = ""
        self.password = ""
        self.authenticationEndpoint = URL(string: "http://localhost")!
    }

    func authenticate(onSuccess: @escaping (String) -> Void, onFailure: @escaping (Error) -> Void) {

    }

    func authenticate() async throws -> String {
        return "test"
    }
}

class MockDataStoreStack: DataStoreStack {
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
        DataCapturing.Measurement(identifier: 0),
        DataCapturing.Measurement(identifier: 1),
        DataCapturing.Measurement(identifier: 2)
    ]

    func delete(measurement: Int64) throws {

    }

    func delete(event: DataCapturing.Event) throws {

    }

    func clean(measurement: Int64) throws {

    }

    func createMeasurement(at time: Date, inMode mode: String) throws -> DataCapturing.Measurement {
        return DataCapturing.Measurement(identifier: 0)
    }

    func createEvent(of type: DataCapturing.EventType, withValue: String?, time: Date, parent: inout DataCapturing.Measurement) throws -> DataCapturing.Event {
        return DataCapturing.Event(type: .lifecycleStart, measurement: DataCapturing.Measurement(identifier: 0))
    }

    func appendNewTrack(to measurement: inout DataCapturing.Measurement) throws {

    }

    func save(measurement: DataCapturing.Measurement) throws -> DataCapturing.Measurement {
        return DataCapturing.Measurement(identifier: 0)
    }

    func save(locations: [DataCapturing.LocationCacheEntry], in measurement: inout DataCapturing.Measurement) throws {

    }

    func save(accelerations: [DataCapturing.SensorValue], rotations: [DataCapturing.SensorValue], directions: [DataCapturing.SensorValue], in measurement: inout DataCapturing.Measurement) throws {

    }

    func load(measurementIdentifiedBy identifier: Int64) throws -> DataCapturing.Measurement {
        return DataCapturing.Measurement(identifier: 0)
    }

    func loadMeasurements() throws -> [DataCapturing.Measurement] {
        return [DataCapturing.Measurement]()
    }

    func loadEvents(typed type: DataCapturing.EventType, forMeasurement measurement: DataCapturing.Measurement) throws -> [DataCapturing.Event] {
        return [DataCapturing.Event]()
    }

    func loadSynchronizableMeasurements() throws -> [DataCapturing.Measurement] {
        return [DataCapturing.Measurement]()
    }

    func loadClean(track: inout DataCapturing.Track) throws -> [DataCapturing.GeoLocation] {
        return [DataCapturing.GeoLocation]()
    }

    func countGeoLocations(forMeasurement measurement: DataCapturing.Measurement) throws -> Int {
        return 0
    }
}

class MockSynchronizer: Synchronizer {
    var handler: [(DataCapturing.DataCapturingEvent, DataCapturing.Status) -> Void] = []

    var syncOnWiFiOnly: Bool = true

    var authenticator: DataCapturing.Authenticator = MockAuthenticator()

    func syncChecked() {

    }

    func sync() {

    }

    func activate() throws {

    }

    func deactivate() {
        
    }


}

#endif
