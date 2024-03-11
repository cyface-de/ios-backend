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

import Foundation

/**
A mocked upload that does not get data from a CoreData store or something similar but just provides the same hardcoded data on each invocation.

 The test data provided via this upload is randomly generated. The numbers have no meaning.

 - author: Klemens Muthmann
 - version: 2.1.0
 */
class MockUpload: Upload {

    static func == (lhs: MockUpload, rhs: MockUpload) -> Bool {
        return lhs.measurement == rhs.measurement
        }

    /// The measurement to upload.
    var measurement: FinishedMeasurement

    /// The counter for this uploads failures.
    var failedUploadsCounter: Int = 0

    /// Check this to see whether `onSuccess` has been called
    var wasSuccessful = false

    /// An optionally empty location to store the upload at.
    var location: URL?

    /// Initialize this class with a simulated measurement identifier.
    init(measurement: FinishedMeasurement) {
        self.measurement = measurement
    }

    // MARK: - Methods

    /// Provide non sense test meta data about this upload.
    func metaData() throws -> MetaData {
        let ret = MetaData(
            locationCount: 3,
            formatVersion: 2,
            startLocLat: 1.0,
            startLocLon: 1.0,
            startLocTS: Date(timeIntervalSince1970: 10_000),
            endLocLat: 1.0,
            endLocLon: 1.0,
            endLocTS: Date(timeIntervalSince1970: 10_100),
            measurementId: 1,
            osVersion: "ios12",
            applicationVersion: "10.0.0",
            length: 10.0,
            modality: "BICYCLE"
        )
        return ret
    }

    /// Some random test data to upload.
    func data() -> Data {
        let bundle = Bundle.module
        guard let path = bundle.path(forResource: "serializedFixture", ofType: "cyf") else {
            fatalError()
        }

        guard let ret = FileManager.default.contents(atPath: path) else {
            fatalError()
        }

        return ret
    }

    func onSuccess() throws {
        wasSuccessful = true
    }

    func onFailed() throws {
        wasSuccessful = false
    }
}
