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
import Alamofire
@testable import DataCapturing

/**
 Tests that creating server connections works as expected.

 - Author: Klemens Muthmann
 - Since: 4.0.1
 - Version: 1.1.3
 */
class ServerConnectionTest: XCTestCase {
    /// A CoreData stack used to load data to transmit from.
    var coreDataStack: CoreDataManager!
    /// The object of the class under test.
    var oocut: ServerConnection!
    /// The CoreData data model used by this test.
    static let dataModel = try! CoreDataManager.load()

    /// Initial setup the server connection and the CoreData stack.
    override func setUp() {
        let expectation = self.expectation(description: "CoreData stack started successfully!")

        do {
            coreDataStack = CoreDataManager(storeType: NSInMemoryStoreType, migrator: CoreDataMigrator(), modelName: "CyfaceModel", model: ServerConnectionTest.dataModel)
            try coreDataStack.setup(bundle: Bundle(for: type(of: coreDataStack))) { [weak self] (error) in
                if let error = error {
                    XCTFail("Unable to setup CoreData stack due to: \(error).")
                }
                guard let self = self else {
                    return
                }
                    guard let url = URL(string: "http://localhost:8080/api/v2") else {
                        fatalError()
                    }
                    let authenticator = StaticAuthenticator()
                    self.oocut = ServerConnection(apiURL: url, authenticator: authenticator, onManager: self.coreDataStack)

                    expectation.fulfill()
            }
        } catch {
            XCTFail("Unable to setup CoreData stack due to: \(error).")
        }
        
        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail("ServerConnectionTest timed out \(error).")
            }
        }
    }

    /**
     Tests that creating a common multi part server request works as expected and creates the expected meta data.
     */
    func testCreateServerRequest_HappyPath() throws {
        // Arrange
        let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
        let identifier = try persistenceLayer.nextIdentifier()
        let measurement = try FakeMeasurementImpl.fakeMeasurement(identifier: identifier).appendTrackAnd().addGeoLocationsAnd(countOfGeoLocations: 10).addAccelerations(countOfAccelerations: 1_000).build(persistenceLayer)

        let data = MultipartFormData()
        do {
            // Act
            try oocut.create(request: data, for: measurement.identifier)

            // Assert
            do {
                let formData = try data.encode()
                let decodedRequest = String(decoding: formData, as: UTF8.self)
                XCTAssertTrue(decodedRequest.contains("startLocLat"))
                XCTAssertTrue(decodedRequest.contains("startLocLon"))
                XCTAssertTrue(decodedRequest.contains("startLocTs"))
                XCTAssertTrue(decodedRequest.contains("endLocLat"))
                XCTAssertTrue(decodedRequest.contains("endLocLon"))
                XCTAssertTrue(decodedRequest.contains("endLocTs"))

                XCTAssertTrue(decodedRequest.contains("deviceId"))
                XCTAssertTrue(decodedRequest.contains("measurementId"))
                XCTAssertTrue(decodedRequest.contains("deviceType"))
                XCTAssertTrue(decodedRequest.contains("osVersion"))
                XCTAssertTrue(decodedRequest.contains("appVersion"))
                XCTAssertTrue(decodedRequest.contains("length"))
                XCTAssertTrue(decodedRequest.contains("locationCount"))
                XCTAssertTrue(decodedRequest.contains("fileToUpload"))
                XCTAssertTrue(decodedRequest.contains("vehicle"))
            } catch {
                XCTFail("Unable to encode request! Error \(error)")
            }
        } catch {
            XCTFail("Unexpected error \(error.localizedDescription)")
        }
    }

    /**
        Tests that creating a multi part server request works even if the first and the last track of the measurement contain no data.
     */
    func testCreateMetaData_WithEmptyTracks() throws {
        let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
        // TODO: Track was not saved to db!!!
        let identifier = try persistenceLayer.nextIdentifier()
        let measurement = try FakeMeasurementImpl.fakeMeasurement(identifier: identifier).appendTrack().appendTrackAnd().addGeoLocationsAnd(countOfGeoLocations: 10).addAccelerations(countOfAccelerations: 1_000).appendTrack().build(persistenceLayer)

        let data = MultipartFormData()
        do {
            // Act
            try oocut.create(request: data, for: measurement.identifier)

            // Assert
            do {
                let formData = try data.encode()
                let decodedRequest = String(decoding: formData, as: UTF8.self)
                XCTAssertTrue(decodedRequest.contains("startLocLat"))
                XCTAssertTrue(decodedRequest.contains("startLocLon"))
                XCTAssertTrue(decodedRequest.contains("startLocTs"))
                XCTAssertTrue(decodedRequest.contains("endLocLat"))
                XCTAssertTrue(decodedRequest.contains("endLocLon"))
                XCTAssertTrue(decodedRequest.contains("endLocTs"))
            } catch {
                XCTFail("Unable to encode request! Error \(error)")
            }
        } catch {
            XCTFail("Unexpected error \(error.localizedDescription)")
        }
    }

    /**
     This test, tries to upload some data to a Cyface server. It should usually be ignored, since it requires an actual server to run.

     To enable this test you need to exchange the `backgroundSessionManager` in `ServerConnection` by a regular `sessionManager` and remove (or comment) the `backgroundSessionManager` in the `Networking` class. The reason for this is, that a simulator is incable of background uploads.

     - Throws: some unspecified errors from within *CoreData*
     */
    func ignore_testUploadMeasurement_HappyPath() throws {
        let url = URL(string: "http://192.168.2.113:8080")!.appendingPathComponent("api").appendingPathComponent("v2")
        let authenticator = CredentialsAuthenticator(authenticationEndpoint: url)
        authenticator.username = "admin"
        authenticator.password = "secret"
        let serverConnection = ServerConnection(apiURL: url, authenticator: authenticator, onManager: coreDataStack)

        let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
        let identifier = try persistenceLayer.nextIdentifier()
        let measurement = try FakeMeasurementImpl.fakeMeasurement(identifier: identifier).appendTrackAnd().addGeoLocationsAnd(countOfGeoLocations: 2).addAccelerations(countOfAccelerations: 2).build(persistenceLayer)

        let measurementIdentifier = measurement.identifier
        let promise = expectation(description: "Expect call to return 201.")
        serverConnection.sync(measurement: measurement.identifier, onSuccess: {synchronizedMeasurement in
            do {
                _ = try persistenceLayer.load(measurementIdentifiedBy: synchronizedMeasurement)
                XCTAssertEqual(synchronizedMeasurement, measurementIdentifier)
                promise.fulfill()
            } catch {
                fatalError()
            }
        }, onFailure: {_, status in
            XCTFail("Error. Status Code was \(status).")
            promise.fulfill()
        })

        wait(for: [promise], timeout: 6000)
    }
}
