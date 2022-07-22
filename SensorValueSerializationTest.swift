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

    func testSerializeAccelerations() throws {
        let sensorValues = [
            SensorValue(timestamp: Date(timeIntervalSince1970: 1.0), x: 0.016448974609375, y: 0.00030517578125, z: -1.000518798828125),
            SensorValue(timestamp: Date(timeIntervalSince1970: 2.0), x: 0.016448974609375, y: 0.0006256103515625, z: -1.0010223388671875),
            SensorValue(timestamp: Date(timeIntervalSince1970: 3.0), x: 0.01702880859375, y: -9.1552734375e-05, z: -1.001861572265625),
            SensorValue(timestamp: Date(timeIntervalSince1970: 4.0), x: 0.016082763671875, y: -0.0001678466796875, z: -1.0012664794921875),
            SensorValue(timestamp: Date(timeIntervalSince1970: 5.0), x: 0.0164947509765625, y: -0.001373291015625, z: -1.0015716552734375)]

        let expectedResult = [
            SensorValue(timestamp: Date(timeIntervalSince1970: 1.0), x: 0.016, y: 0.000, z: -1.000),
            SensorValue(timestamp: Date(timeIntervalSince1970: 2.0), x: 0.016, y: 0.000, z: -1.001),
            SensorValue(timestamp: Date(timeIntervalSince1970: 3.0), x: 0.017, y: 0.000, z: -1.001),
            SensorValue(timestamp: Date(timeIntervalSince1970: 4.0), x: 0.016, y: -0.000, z: -1.001),
            SensorValue(timestamp: Date(timeIntervalSince1970: 5.0), x: 0.016, y: -0.001, z: -1.001)]

        let oocut = SensorValueSerializer()

        let serializedAccelerations = try oocut.serialize(serializable: sensorValues)

        let deserializedAccelerations = try oocut.deserialize(data: serializedAccelerations)

        XCTAssertEqual(sensorValues.count, deserializedAccelerations.count)
        for i in 0..<sensorValues.count {
            XCTAssertEqual(expectedResult[i], deserializedAccelerations[i])
        }
    }
}
