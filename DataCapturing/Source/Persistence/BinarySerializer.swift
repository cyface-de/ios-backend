/*
 * Copyright 2018-2022 Cyface GmbH
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
import DataCompression
import os.log

/// The current version of the Cyface binary format.
let dataFormatVersion: UInt16 = 2
let dataFormatVersionBytes = withUnsafeBytes(of: dataFormatVersion.bigEndian) {
    Data($0)
}

/**
 Protocol that must be fullfilled by a serializer to transform an object into the Cyface binary format. The associated type `Serializable` is a placeholder for the type of object to serialize and deserialize.
 
 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 2.0.0
 */
protocol BinarySerializer {

    /// The type of the item to serialize.
    associatedtype Serializable

    // MARK: - Methods
    /**
     Serializes the provided serializable into a Cyface binary format representation. This only works for supported object types such as `MeasurementMO`, `Acceleration` and `GeoLocationMO`.
     
     - Parameter serializable: The object to serialize
     - Returns: A binary format representation of the provided object
     - Throws:
     - `SerializationError.missingData` If no track data was found.
     - `SerializationError.invalidData` If the database provided inconsistent and wrongly typed data. Something is seriously wrong in these cases.
     */
    func serialize(serializable: Serializable) throws -> Data

    /**
     Serializes the provided `measurement` and compresses the returned data.
     
     - Parameter serializable: The `serializable` object to serialize
     - Returns: The serialized measurement in the compressed Cyface binary format
     - Throws:
     */
    func serializeCompressed(serializable: Serializable) throws -> Data

}

// MARK: - Implementation

extension BinarySerializer {
    /**
     Serializes and compresses the provided serializable and returns the serialized variant.
     
     - Parameter serializable: The object to serialize.
     - Throws: `SerializationError.compressionFailed` If compressing the provided `Serializable` failed for some reason.
     - Throws: `SerializationError.missingData` If no track data was found.
     - Throws: `SerializationError.invalidData` If the database provided inconsistent and wrongly typed data. Something is seriously wrong in these cases.
     - Returns: A compressed variant of the serialized data.
     */
    func serializeCompressed(serializable: Serializable) throws -> Data {
        let res = try serialize(serializable: serializable)

        guard let compressed = res.deflate() else {
            os_log("Unable to compress data.",
                   log: OSLog.init(subsystem: "BinarySerializer",
                                   category: "de.cyface"),
                   type: .error)
            throw SerializationError.compressionFailed
        }

        return compressed
    }
}

/*
 In contrast to Apples proposals, these are not implemented as structs but classes. The reason is that none of the implementations contain a state and I see absolutely no reason to copy stateless instances around all the time. Probably slows down everything.
 */

/**
 A serializer for measurements into the Cyface binary format represenation.
 
 - Author: Klemens Muthmann
 - Since: 2.0.0
 - Version: 2.0.0
 */
class MeasurementSerializer: BinarySerializer {
    static let centimetersInAMeter = 100.0
    static let geoLocationAccuracy = 6
    /// Serializer to transform acceleration objects
    let accelerationsFile = SensorValueFile(fileType: SensorValueFileType.accelerationValueType)
    let rotationsFile = SensorValueFile(fileType: SensorValueFileType.rotationValueType)
    let directionsFile = SensorValueFile(fileType: SensorValueFileType.directionValueType)

    /**
     Serializes the provided `measurement` into its Cyface Binary Format specification in the form:
     - 2 Bytes: Version of the file format.
     - 4 Bytes: Count of geo locations
     - 4 Bytes: Count of accelerations
     - 4 Bytes: Count of rotations (not used on iOS yet)
     - 4 Bytes: Count of directions (not used on iOS yet)
     
     - Parameter serializable: The measurement to serialize.
     - Throws:
        - `SerializationError.missingData` If no track data was found.
        - `SerializationError.invalidData` If the database provided inconsistent and wrongly typed data. Something is seriously wrong in these cases.
     */
    func serialize(serializable measurement: Measurement) throws -> Data {
        var protosMeasurement = De_Cyface_Protos_Model_MeasurementBytes()
        protosMeasurement.formatVersion = UInt32(dataFormatVersion)
        if let events = measurement.events?.array as? [Event] {
            protosMeasurement.events = serialize(events: events)
        } else {
            protosMeasurement.events = []
        }
        protosMeasurement.locationRecords = De_Cyface_Protos_Model_LocationRecords()

        let firstTimestamp = UInt64DiffValue(start: UInt64(0))
        let firstAccuracy = Int32DiffValue(start: Int32(0))
        let firstLatitude = Int32DiffValue(start: Int32(0))
        let firstLongitude = Int32DiffValue(start: Int32(0))
        let firstSpeed = Int32DiffValue(start: Int32(0))
        protosMeasurement.locationRecords.timestamp = []
        protosMeasurement.locationRecords.speed = []
        protosMeasurement.locationRecords.latitude = []
        protosMeasurement.locationRecords.longitude = []
        protosMeasurement.locationRecords.accuracy = []

        var records = protosMeasurement.locationRecords
        try PersistenceLayer.traverseTracks(ofMeasurement: measurement) { _, location in

            do {
                records.timestamp.append(try firstTimestamp.diff(value: UInt64(location.timestamp)))
            } catch {
                throw SerializationError.nonSerializableLocationTimestamp(cause: error)
            }
            do {
                records.accuracy.append(try firstAccuracy.diff(value: Int32(location.accuracy * MeasurementSerializer.centimetersInAMeter)))
            } catch {
                throw SerializationError.nonSerializableAccuracy(cause: error)
            }
            do {
                records.latitude.append(try firstLatitude.diff(value: convert(coordinate: location.lat)))
            } catch {
                throw SerializationError.nonSerializableLatitude(cause: error)
            }
            do {
                records.longitude.append(try firstLongitude.diff(value: convert(coordinate: location.lon)))
            } catch {
                throw SerializationError.nonSerializableLongitude(cause: error)
            }
            do {
                records.speed.append(try firstSpeed.diff(value: Int32(location.speed * MeasurementSerializer.centimetersInAMeter)))
            } catch {
                throw SerializationError.nonSerializableSpeed(cause: error)
            }
        }
        protosMeasurement.locationRecords = records

        let accelerationsData = try accelerationsFile.data(for: measurement)
        protosMeasurement.accelerationsBinary = accelerationsData
        let directionsData = try directionsFile.data(for: measurement)
        protosMeasurement.directionsBinary = directionsData
        let rotationsData = try rotationsFile.data(for: measurement)
        protosMeasurement.rotationsBinary = rotationsData
        let serializedData = try protosMeasurement.serializedData()
        var ret = Data(dataFormatVersionBytes)
        ret.append(serializedData)

        return ret
    }

    private func serialize(events: [Event]) -> [De_Cyface_Protos_Model_Event] {
        var ret = [De_Cyface_Protos_Model_Event]()
        for event in events {
            ret.append(De_Cyface_Protos_Model_Event.with {
                if let time = event.time {
                    $0.timestamp = DataCapturingService.convertToUtcTimestamp(date: time as Date)
                }
                if let value = event.value {
                    $0.value = value
                }
                switch event.typeEnum {
                case .lifecycleStart:
                    $0.type = De_Cyface_Protos_Model_Event.EventType.lifecycleStart
                case .lifecycleStop:
                    $0.type = De_Cyface_Protos_Model_Event.EventType.lifecycleStop
                case .lifecyclePause:
                    $0.type = De_Cyface_Protos_Model_Event.EventType.lifecyclePause
                case .lifecycleResume:
                    $0.type = De_Cyface_Protos_Model_Event.EventType.lifecycleResume
                case .modalityTypeChange:
                    $0.type = De_Cyface_Protos_Model_Event.EventType.modalityTypeChange
                }
            })
        }
        return ret
    }

    private func convert(coordinate: Double) -> Int32 {
        var shifter = 1.0
        for _ in 1...MeasurementSerializer.geoLocationAccuracy {
            shifter *= 10.0
        }
        return Int32(coordinate*shifter)
    }
}

/**
 A serializer for accelerations into the Cyface binary format representation
 
 - Author: Klemens Muthmann
 - Since: 2.0.0
 - Version: 2.0.0
 - Note: This class was called `AccelerationSerializer` in SDK version prior to 6.0.0.
 */
class SensorValueSerializer: BinarySerializer {
    private static let millimetersInAMeter = 1_000.0

    /**
     Serializes an array of sensor values into binary format of the form:
     - 8 Bytes: timestamp as long
     - 8 Bytes: x as double
     - 8 Bytes: y as double
     - 8 Bytes: z as double
     
     - Parameter serializable: The array of sensor values to serialize.
     - Returns: An array of serialized bytes.
     - Throws: `BinarySerializationError.emptyData` if the provided `serializable` array is empty.
     - Throws: `BinaryEncodingError` if encoding fails.
     */
    func serialize(serializable values: [SensorValue]) throws -> Data {
        guard !values.isEmpty else {
            throw BinarySerializationError.emptyData
        }
        let timestampDiffValue = UInt64DiffValue(start: UInt64(0))
        let xDiffValue = Int32DiffValue(start: Int32(0))
        let yDiffValue = Int32DiffValue(start: Int32(0))
        let zDiffValue = Int32DiffValue(start: Int32(0))

        var timestamps = [UInt64]()
        var xValues = [Int32]()
        var yValues = [Int32]()
        var zValues = [Int32]()
        for valueIndex in values.indices {
            do {
            timestamps.append(try timestampDiffValue.diff(value: DataCapturingService.convertToUtcTimestamp(date: values[valueIndex].timestamp)))
            } catch {
                throw SerializationError.nonSerializableSensorValueTimestamp(cause: error)
            }
            do {
            xValues.append(try xDiffValue.diff(value: Int32(values[valueIndex].x*SensorValueSerializer.millimetersInAMeter)))
            } catch {
                throw SerializationError.nonSerializableXValue(cause: error)
            }
            do {
            yValues.append(try yDiffValue.diff(value: Int32(values[valueIndex].y*SensorValueSerializer.millimetersInAMeter)))
            } catch {
                throw SerializationError.nonSerializableYValue(cause: error)
            }
            do {
            zValues.append(try zDiffValue.diff(value: Int32(values[valueIndex].z*SensorValueSerializer.millimetersInAMeter)))
            } catch {
                throw SerializationError.nonSerializableZValue(cause: error)
            }
        }

        let accelerations = De_Cyface_Protos_Model_Accelerations.with {
            $0.timestamp = timestamps
            $0.x = xValues
            $0.y = yValues
            $0.z = zValues
        }

        let ret = De_Cyface_Protos_Model_AccelerationsBinary.with {
            $0.accelerations = [accelerations]
        }

        return try ret.serializedData()
    }

    /**
         Deserializes the provided `data` into a `Serializable`. Only use this if your data is not compressed. Otherwise use `deserializeCompressed(:Data)`.
         - Parameters:
            - data: The `data` to deserialize
         - Returns: An object of type `Serializable` created from the provided `data`
         - Throws: `UInt64UnDiffValueError.overflow` if reversing the undiff format causes an unsigned 64 bit integer to overflow.
         - Throws: `Int32UnDiffValueError.overflow` if reversing the undiff format causes a signed 32 bit integer to overflow.

         */
        func deserialize(data: Data) throws -> [SensorValue] {

            let deserializedValues = try De_Cyface_Protos_Model_AccelerationsBinary(serializedData: data)
            var ret: [SensorValue] = []

            let timestampUnDiff = UInt64UnDiffValue(start: 0)
            let axUnDiff = Int32UnDiffValue(start: 0)
            let ayUnDiff = Int32UnDiffValue(start: 0)
            let azUnDiff = Int32UnDiffValue(start: 0)

            for batch in deserializedValues.accelerations {
                for accelerationsIndex in batch.timestamp.indices {
                    let timestamp = try timestampUnDiff.undiff(value: batch.timestamp[accelerationsIndex])
                    let ax = Double(try axUnDiff.undiff(value: batch.x[accelerationsIndex]))/1000.0
                    let ay = Double(try ayUnDiff.undiff(value: batch.y[accelerationsIndex]))/1000.0
                    let az = Double(try azUnDiff.undiff(value: batch.z[accelerationsIndex]))/1000.0

                    let value = SensorValue(timestamp: Date(timeIntervalSince1970: Double(timestamp)/1_000), x: ax, y: ay, z: az)
                    ret.append(value)
                }
            }

            return ret
        }

    public enum BinarySerializationError: Error {
        case emptyData
    }
}

class UInt64DiffValue {
    var previousValue: UInt64

    init(start: UInt64) {
        previousValue = start
    }

    func diff(value: UInt64) throws -> UInt64 {
        let ret = value.subtractingReportingOverflow(previousValue)
        guard !ret.overflow else {
            throw UInt64DiffValueError.overflow(minuend: value, subtrahend: previousValue)
        }
        previousValue = value
        return ret.partialValue
    }

    enum UInt64DiffValueError: Error {
        case overflow(minuend: UInt64, subtrahend: UInt64)
    }
}

class UInt64UnDiffValue {
    var previousValue: UInt64

    init(start: UInt64) {
        previousValue = start
    }

    func undiff(value: UInt64) throws -> UInt64 {
        let ret = previousValue.addingReportingOverflow(value)
        guard !ret.overflow else {
            throw UInt64UnDiffValueError.overflow(firstSummand: previousValue, secondSummand: value)
        }
        previousValue = ret.partialValue
        return ret.partialValue
    }

    enum UInt64UnDiffValueError: Error {
        case overflow(firstSummand: UInt64, secondSummand: UInt64)
    }
}

class Int32DiffValue {
    var previousValue: Int32

    init(start: Int32) {
        previousValue = start
    }

    func diff(value: Int32) throws -> Int32 {
        let ret = value.subtractingReportingOverflow(previousValue)
        guard !ret.overflow else {
            throw Int32DiffValueError.overflow(minuend: value, subtrahend: previousValue)
        }
        previousValue = value
        return ret.partialValue
    }

    enum Int32DiffValueError: Error {
        case overflow(minuend: Int32, subtrahend: Int32)
    }
}

class Int32UnDiffValue {
    var previousValue: Int32

    init(start: Int32) {
        previousValue = start
    }

    func undiff(value: Int32) throws -> Int32 {
        let ret = previousValue.addingReportingOverflow(value)
        guard !ret.overflow else {
            throw Int32UnDiffValueError.overflow(firstSummand: previousValue, secondSummand: value)
        }
        previousValue = value
        return ret.partialValue
    }

    enum Int32UnDiffValueError: Error {
        case overflow(firstSummand: Int32, secondSummand: Int32)
    }
}

/// Extension to the `BinaryInteger` class providing the functionality to extract some bytes.
extension BinaryInteger {
    /**
     Extracts bytes from this object.
     
     - Returns: The provided bytes as an array of 8 bit unsigned integers.
     */
    func extractBytes() -> [UInt8] {
        var ret = [UInt8]()

        var buffer = self
        for _ in 0..<(self.bitWidth/8) {
            let byteValue = UInt8(truncatingIfNeeded: buffer)
            ret.append(byteValue)
            buffer = buffer >> 8
        }

        return ret
    }
}

/**
 An enumeration of all the possible errors thrown during serialization.
 
 ````
 case compressionFailed
 case decompressionFailed
 case missingData
 case invalidData
 ````

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 1.0.0
 */
enum SerializationError: Error {
    /// Thrown if compression of serialized data was not successful.
    case compressionFailed
    /// Thrown if decompression of serialized data was not successful.
    case decompressionFailed
    /// Thrown if data required for serialization or deserialization is missing.
    case missingData
    /// Thrown if the data read was no valid or some corrupted Cyface binray format.
    case invalidData
    case nonSerializableSensorValueTimestamp(cause: Error)
    case nonSerializableXValue(cause: Error)
    case nonSerializableYValue(cause: Error)
    case nonSerializableZValue(cause: Error)
    case nonSerializableLocationTimestamp(cause: Error)
    case nonSerializableAccuracy(cause: Error)
    case nonSerializableSpeed(cause: Error)
    case nonSerializableLatitude(cause: Error)
    case nonSerializableLongitude(cause: Error)
}
