/*
 * Copyright 2018 - 2022 Cyface GmbH
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
import CoreData
@testable import DataCapturing

/**
 Test the serialization of lists of sensor values.

 - author: Klemens Muthmann
 - version: 1.0.0
 */
class SensorValueSerializationTest: XCTestCase {
    /// Test the serialization of batches of sensor values.
    func testSerializeSensorValues() throws {
        let sensorValueSerializer = SensorValueSerializer()

        // 1
        let firstBatch = try sensorValueSerializer.serialize(serializable: [SensorValue(timestamp: Date(timeIntervalSince1970: 10.000), x: 1.0, y: 1.0, z: 1.0), SensorValue(timestamp: Date(timeIntervalSince1970: 10.100), x: 1.1, y: 1.1, z: 1.1), SensorValue(timestamp: Date(timeIntervalSince1970: 10.200), x: -2.0, y: -2.0, z: -2.0)])

        // 2
        let secondBatch = try sensorValueSerializer.serialize(serializable: [SensorValue(timestamp: Date(timeIntervalSince1970: 10.300), x: 1.5, y: 1.5, z: 1.5), SensorValue(timestamp: Date(timeIntervalSince1970: 10.400), x: 1.2, y: 1.2, z: 1.2)])

        // 3
        var data = Data()
        data.append(contentsOf: firstBatch)
        data.append(contentsOf: secondBatch)


        // 4
        var measurementBytes = De_Cyface_Protos_Model_MeasurementBytes()
        measurementBytes.formatVersion = 2
        measurementBytes.accelerationsBinary = data

        let deserializedMeasurement = try De_Cyface_Protos_Model_Measurement(serializedData: measurementBytes.serializedData())

        XCTAssertEqual(deserializedMeasurement.accelerationsBinary.accelerations[0].z[0], 1000)
        XCTAssertEqual(deserializedMeasurement.accelerationsBinary.accelerations[0].z[1], 100)
        XCTAssertEqual(deserializedMeasurement.accelerationsBinary.accelerations[0].z[2], -3100)
        XCTAssertEqual(deserializedMeasurement.accelerationsBinary.accelerations[0].timestamp[0],10_000)
        XCTAssertEqual(deserializedMeasurement.accelerationsBinary.accelerations[0].timestamp[1],100)
        XCTAssertEqual(deserializedMeasurement.accelerationsBinary.accelerations[0].timestamp[2],100)
    }
}
