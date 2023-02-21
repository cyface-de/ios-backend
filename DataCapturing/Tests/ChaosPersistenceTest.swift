//
//  ChaosPersistenceTest.swift
//  DataCapturing-Unit-Tests
//
//  Created by Klemens Muthmann on 20.02.23.
//

import XCTest
import CoreData
@testable import DataCapturing

/**
 Runs CoreData write operations in multiple parallel threads to make sure, that no concurrency issues arise.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
class ChaosPersistenceTest: XCTestCase {
    /// A `PersistenceLayer` used for testing.
    var oocut: PersistenceLayer?
    /// Some test data.
    var fixture: DataCapturing.Measurement?

    /// Create the object of the class under test as well as some test fixture.
    override func setUp() {
        do {
            let coreDataManager = try CoreDataManager(storeType: NSInMemoryStoreType)
            let bundle = Bundle(for: type(of: coreDataManager))
            let expectation = expectation(description: "Setup finished")
            coreDataManager.setup(bundle: bundle) { [weak self] error in
                defer {
                    expectation.fulfill()
                }

                if let error = error {
                    XCTFail(error.localizedDescription)
                    return
                }

                guard let self = self else {
                    XCTFail("Test object was gone before initialization was complete!")
                    return
                }

                let oocut = PersistenceLayer(onManager: coreDataManager)

                do {
                    var fixture = try oocut.createMeasurement(at: Int64(Date().timeIntervalSince1970*1000), inMode: "BICYCLE")
                    try oocut.appendNewTrack(to: &fixture)
                    try oocut.save(locations: [TestFixture.randomLocation(), TestFixture.randomLocation()], in: &fixture)
                    try oocut.save(accelerations: [TestFixture.randomAcceleration(), TestFixture.randomAcceleration(), TestFixture.randomAcceleration()], in: &fixture)
                    self.fixture = fixture
                } catch {
                    XCTFail(error.localizedDescription)
                    return
                }

                self.oocut = oocut
            }

            waitForExpectations(timeout: 5) { error in
                if let error = error {
                    XCTFail(error.localizedDescription)
                }
            }
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    /// Remove the object of the class under test as well as the test fixture after each test.
    override func tearDown() {
        oocut = nil
        fixture = nil
    }

    /// Create a bunch of measurements in parrallel.
    func testCreateMeasurementChaos() {
        // Arrange
        var identifier = [Int64]()
        guard let oocut = oocut else {
            XCTFail("Object of class under test was not properly initialized!")
            return
        }

        // Act
        chaosTest(executions: 1000) {
            let createdMeasurement = try oocut.createMeasurement(at: Int64(Date().timeIntervalSince1970*1000), inMode: "BICYCLE")

            // Assert
            XCTAssertFalse(identifier.contains(createdMeasurement.identifier))
            identifier.append(createdMeasurement.identifier)
        }
    }

    /// Clean the fixture measurement a bunch of times in parallel.
    func testCleanMeasurementChaos() {
        // Arrange
        guard let oocut = oocut else {
            XCTFail("Object of class under test was not properly initialized!")
            return
        }
        guard let fixture = fixture else {
            XCTFail("Fixture was not properly initialized!")
            return
        }

        chaosTest(executions: 1000) {
            try oocut.clean(measurement: fixture.identifier)
        }
    }

    /// Append tracks to the fixture in parallel.
    func testAppendNewTrackChaos() throws {
        // Arrange
        guard let oocut = oocut else {
            XCTFail("Object of class under test was not properly initialized!")
            return
        }
        var measurement = try oocut.createMeasurement(at: Int64(Date().timeIntervalSince1970*1000), inMode: "BICYCLE")

        // Act / Assert
        chaosTest(executions: 1000) {
            try oocut.appendNewTrack(to: &measurement)
        }
    }

    /// This calls all the writing functions (except for delete) randomly in parallel.
    func testTotalChaos() {
        guard let oocut = oocut else {
            XCTFail("Object of class under test was not properly initialized!")
            return
        }

        guard let fixture = fixture else {
            XCTFail("Test fixture was not properly initialized!")
            return
        }

        var measurementsWithAtLeastOneTrack = Array<DataCapturing.Measurement>()
        var measurements = Array<DataCapturing.Measurement>()
        measurementsWithAtLeastOneTrack.append(fixture)
        measurements.append(fixture)
        chaosTest(executions: 5000) {
            let commandIndex = Int.random(in: 0...3)
            do {
                if commandIndex == 0 {
                    let createdMeasurement = try oocut.createMeasurement(at: Int64(Date().timeIntervalSince1970*1000), inMode: "BICYCLE")
                } else if commandIndex == 1 {
                    var randomMeasurement = self.randomMeasurement(from: measurementsWithAtLeastOneTrack)
                    try oocut.appendNewTrack(to: &randomMeasurement)
                    measurementsWithAtLeastOneTrack.append(randomMeasurement)
                } else if commandIndex == 2 {
                    var randomMeasurement = self.randomMeasurement(from: measurementsWithAtLeastOneTrack)
                    try oocut.save(locations: [TestFixture.randomLocation(), TestFixture.randomLocation()], in: &randomMeasurement)
                } else if commandIndex == 3 {
                    var randomMeasurement = self.randomMeasurement(from: measurements)
                    try oocut.clean(measurement: randomMeasurement.identifier)
                } else if commandIndex == 4 {
                    var randomMeasurement = self.randomMeasurement(from: measurements)
                    let randomEventType = EventType.allCases.randomElement()!
                    if randomEventType == .modalityTypeChange {
                        let randomModality = ["CAR", "BICYCLE", "WALKING", "BUS", "TRAIN"].randomElement()!
                        try oocut.createEvent(of: randomEventType, withValue: randomModality, parent: &randomMeasurement)
                    } else {
                        try oocut.createEvent(of: randomEventType, parent: &randomMeasurement)
                    }
                } else if commandIndex == 5 {
                    var randomMeasurement = self.randomMeasurement(from: measurementsWithAtLeastOneTrack)
                    try oocut.save(
                        accelerations: [TestFixture.randomAcceleration(), TestFixture.randomAcceleration()],
                        in: &randomMeasurement
                    )
                } else if commandIndex == 6 {
                    var randomMeasurement = self.randomMeasurement(from: measurementsWithAtLeastOneTrack)
                    randomMeasurement.synchronized = true
                    _ = try oocut.save(measurement: randomMeasurement)
                }
            } catch {
                throw ChaosTestError.wrappedError(commandIndex: commandIndex, error: error)
            }
        }
    }

    /// Provide a random measurement from an array of measurements
    func randomMeasurement(from measurements: [DataCapturing.Measurement]) -> DataCapturing.Measurement {
        return measurements[Int.random(in: 0..<measurements.count)]
    }

    /// This function calls the provided closure the number of times of `executions` in parallel with a random sleep time added before each call.
    /// That way it tries to provoke threading issues with the code provided by the closure.
    func chaosTest(executions: Int, closure: @escaping () throws -> ()) {
        // Arrange
        let group = DispatchGroup()

        // Act
        for _ in 0...executions {
            group.enter()

            DispatchQueue.global().async {
                defer {
                    group.leave()
                }

                let sleepVal = UInt32.random(in: 0...999)
                usleep(sleepVal)
                do {
                    try closure()
                } catch {
                    return XCTFail("Execution failed due to: \(error.localizedDescription)")
                }
            }
        }

        let result = group.wait(timeout: DispatchTime.now() + 40)

        // Assert
        XCTAssert(result == .success)
    }
}

/**
  Errors thrown by the chaos test.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
enum ChaosTestError: Error {
    /// An error wrapping another error, thrown by the closure called by the chaos test.
    case wrappedError(commandIndex: Int, error: Error)
}

extension ChaosTestError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .wrappedError(commandIndex: let commandIndex, error: let error):
            let message = NSLocalizedString(
                "de.cyface.ChaosTestError.wrappedError",
                value: """
                Chaos Test failed on command %d due to %@.
                """,
                comment: "Explain to the user on which command the test has failed and why.")
            return String.localizedStringWithFormat(message, commandIndex, error.localizedDescription)
        }
    }
}
