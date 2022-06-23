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
let dataFormatVersion: UInt16 = 1

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
     - Throws:
        - `SerializationError.decompressionFailed` If decompressing the provided `Serializable` failed for some reason.
        - `SerializationError.missingData` If no track data was found.
        - `SerializationError.invalidData` If the database provided inconsistent and wrongly typed data. Something is seriously wrong in these cases.
     - Returns: A compressed variant of the serialized data.
     */
    func serializeCompressed(serializable: Serializable) throws -> Data {
        let res = try serialize(serializable: serializable)

        guard let compressed = res.deflate() else {
            os_log("Unable to compress data.",
                   log: OSLog.init(subsystem: "BinarySerializer",
                                   category: "de.cyface"),
                   type: .error)
            throw SerializationError.decompressionFailed
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
 - Version: 3.0.0
 */
class MeasurementSerializer: BinarySerializer {
    /// The byte order used to serialize data to Cyface binary format.
    static let byteOrder = ByteOrder.bigEndian
    /// Serializer to transform acceleration objects
    let accelerationsFile = SensorValueFile(fileType: SensorValueFileType.accelerationValueType)
    let rotationsFile = SensorValueFile(fileType: SensorValueFileType.rotationValueType)
    let directionsFile = SensorValueFile(fileType: SensorValueFileType.directionValueType)
    /// Serializer to transform geo location objects
    let geoLocationsSerializer = GeoLocationSerializer()

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
        let geoLocations = try PersistenceLayer.collectGeoLocations(from: measurement)

        var dataArray = [UInt8]()
        // add header
        dataArray.append(contentsOf: MeasurementSerializer.byteOrder.convertToBytes(dataFormatVersion))
        dataArray.append(contentsOf: MeasurementSerializer.byteOrder.convertToBytes(UInt32(geoLocations.count)))
        dataArray.append(contentsOf: MeasurementSerializer.byteOrder.convertToBytes(UInt32(measurement.accelerationsCount)))
        dataArray.append(contentsOf: MeasurementSerializer.byteOrder.convertToBytes(UInt32(measurement.rotationsCount)))
        dataArray.append(contentsOf: MeasurementSerializer.byteOrder.convertToBytes(UInt32(measurement.directionsCount)))

        var ret = Data(dataArray)

        let serializedGeoLocations = geoLocationsSerializer.serialize(serializable: geoLocations)
        let serializedAccelerations = try accelerationsFile.data(for: measurement)
        let serializedRotations = try rotationsFile.data(for: measurement)
        let serializedDirections = try directionsFile.data(for: measurement)

        ret.append(serializedGeoLocations)
        ret.append(serializedAccelerations)
        ret.append(serializedRotations)
        ret.append(serializedDirections)

        return ret
    }
}

/**
 A serializer for accelerations into the Cyface binary format representation
 
 - Author: Klemens Muthmann
 - Since: 2.0.0
 - Version: 2.0.1
 - Note: This class was called `AccelerationSerializer` in SDK version prior to 6.0.0.
 */
class SensorValueSerializer: BinarySerializer {
    /**
     Serializes an array of sensor values into binary format of the form:
     - 8 Bytes: timestamp as long
     - 8 Bytes: x as double
     - 8 Bytes: y as double
     - 8 Bytes: z as double
     
     - Parameter serializable: The array of sensor values to serialize.
     - Returns: An array of serialized bytes.
     */
    func serialize(serializable values: [SensorValue]) -> Data {
        var ret = [UInt8]()
        let byteOrder = ByteOrder.bigEndian

        for value in values {
            // 8 Bytes
            ret.append(contentsOf: byteOrder.convertToBytes(DataCapturingService.convertToUtcTimestamp(date: value.timestamp)))
            // 8 Bytes
            ret.append(contentsOf: byteOrder.convertToBytes(value.x.bitPattern))
            // 8 Bytes
            ret.append(contentsOf: byteOrder.convertToBytes(value.y.bitPattern))
            // 8 Bytes
            ret.append(contentsOf: byteOrder.convertToBytes(value.z.bitPattern))
            // 32 Bytes
        }

        return Data(ret)
    }

    /**
     Deserializes the provided `data` into a `Serializable`. Only use this if your data is not compressed. Otherwise use `deserializeCompressed(:Data)`.

     - Parameters:
        - data: The `data` to deserialize
        - count: The amount of sensor values in `data`.
     - Returns: An object of type `Serializable` created from the provided `data`
     - Throws:
        - `SerializationError.invalidData` If there is not enough data for `count` of sensor values.
     */
    func deserialize(data: Data, count: UInt32) throws -> [SensorValue] {
        guard data.count == count*32 else {
            throw SerializationError.invalidData
        }

        let oneEntryInBytes = UInt32(32)
        var ret: [SensorValue] = []
        for index in 0..<count {
            let startIndex = index*oneEntryInBytes

            let timestamp = try MeasurementSerializer.byteOrder.convertToInt64(data[startIndex..<startIndex+8])
            let ax = try MeasurementSerializer.byteOrder.convertToDouble(data[startIndex+8..<startIndex+16])
            let ay = try MeasurementSerializer.byteOrder.convertToDouble(data[startIndex+16..<startIndex+24])
            let az = try MeasurementSerializer.byteOrder.convertToDouble(data[startIndex+24..<startIndex+32])

            let value = SensorValue(timestamp: Date(timeIntervalSince1970: Double(timestamp)/1_000), x: ax, y: ay, z: az)
            ret.append(value)
        }

        return ret
    }
}

/**
 A serializer for geo locations into the Cyface binary format representation
 
 - Author: Klemens Muthmann
 - Since: 2.0.0
 - Version: 2.0.0
 */
class GeoLocationSerializer: BinarySerializer {
    /**
     Serializes an array of geo locations into binary format of the form:
     - 8 Bytes: timestamp as long
     - 8 Bytes: latitude as double
     - 8 Bytes: longitude as double
     - 8 Bytes: speed as double
     - 4 Bytes: accuracy as int
     
     - Parameter serializable: The array of locations to serialize.
     - Returns: An array of serialized bytes.
     */
    func serialize(serializable locations: [GeoLocation]) -> Data {
        var ret = [UInt8]()
        let byteOrder = ByteOrder.bigEndian

        for location in locations {
            // 8 Bytes
            let timestamp = location.timestamp
            ret.append(contentsOf: byteOrder.convertToBytes(timestamp))
            // 8 Bytes
            let latBitPattern = location.latitude.bitPattern
            ret.append(contentsOf: byteOrder.convertToBytes(latBitPattern))
            // 8 Bytes
            let lonBitPattern = location.longitude.bitPattern
            ret.append(contentsOf: byteOrder.convertToBytes(lonBitPattern))
            // 8 Bytes
            let speedBitPattern = location.speed.bitPattern
            ret.append(contentsOf: byteOrder.convertToBytes(speedBitPattern))
            // 4 Bytes
            let accuracy = UInt32(location.accuracy*100)
            ret.append(contentsOf: byteOrder.convertToBytes(accuracy))
            // = 36 Bytes
        }

        return Data(ret)
    }
}

/**
 Serializes a list of events to an events file.

 - Author: Klemens Muthmann
 - Version: 1.0.1
 - Since: 5.0.0
 */
public class EventsSerializer: BinarySerializer {

    /**
     Serializes an array of `Event` instaces to a binary representation of the form:
     - 2 Bytes: File version. Currently 1
     - 8 Bytes: Number of events saved
     - For each event:
            - 8 Bytes: Timestamp
            - 2 Bytes: A number representing the type of event
            - 2 Bytes: Number of bytes used by the value
            - X Bytes: The event value.

     - Parameter serializable: The array of events to serialize
     - Returns: The binary representation of the `Event` array.
     */
    func serialize(serializable events: [Event]) throws -> Data {
        var ret = [UInt8]()
        let byteOrder = ByteOrder.bigEndian

        // Add Header
        // Transfer File format version
        ret.append(contentsOf: byteOrder.convertToBytes(Int16(1)))
        // Count of events
        ret.append(contentsOf: byteOrder.convertToBytes(Int32(events.count)))

        // Add all the events
        for event in events {
            // event timestamp; 8 bytes
            let timestamp = Int64(event.time.timeIntervalSince1970 * 1_000)
            ret.append(contentsOf: byteOrder.convertToBytes(timestamp))
            // event type: 2 bytes
            let type = translateType(of: event)
            ret.append(contentsOf: byteOrder.convertToBytes(type))
            // bytes required for the value and the value: 2 + X bytes
            if let serializableValue = event.value?.data(using: .utf8) {
                let serializableValueLengthInBytes = Int16(serializableValue.count)
                ret.append(contentsOf: byteOrder.convertToBytes(serializableValueLengthInBytes))
                ret.append(contentsOf: serializableValue)
            } else {
                ret.append(contentsOf: byteOrder.convertToBytes(Int16(0)))
            }
        }

        return Data(ret)
    }

    /**
     This method translates an events type to a serializable `Int16` representation.

     Altough this is technically not necessary it makes it easier to synchronize the serialization with the Android client, by making the numbers used for each type explicit.

     - Parameter of: The `Event` to translate the type for
     - Returns: The serializable representation of the provided `Event` type.
     */
    private func translateType(of event: Event) -> Int16 {
        switch event.type {
        case .lifecycleStart:
                return 1
        case .lifecycleStop:
                return 2
        case .lifecycleResume:
                return 3
        case .lifecyclePause:
                return 4
        case .modalityTypeChange:
                return 5
        }
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
}

/**
 Enum used to specify the correct byte order. Apple uses little endian while Cyface uses big endian.

 ````
 case bigEndian
 case littleEndian
 ````

 - Author: Klemens Muthmann
 - Version: 1.0.1
 - Since: 2.3.0
 */
enum ByteOrder {
    /// Big endian byte order. The byte with the highest order is the first.
    case bigEndian
    /// little endian byte order. The byte with the lowest order is the first.
    case littleEndian

    /**
     Converts the provided value into a byte representation.

     - Parameters:
     - value: The value to convert to a byte representation.
     - inOrder: The byte order to use. Apple usually uses little endian, while the Cyface binary format is currently in big endian format, because that is the standard on Android and in the backend system.
     - Returns: An array of bytes, representing the provided value.
     */
    func convertToBytes<T: BinaryInteger>(_ value: T) -> [UInt8] {
        let ret = value.extractBytes()
        return self == .bigEndian ? ret.reversed() : ret
    }

    /**
     Converts the provided value into a 64 bit integer value.

     - Parameter data: The data to convert.
     - Returns: The converted `data` as a 64 bit integer.
     - Throws:
     - `SerializationError.invalidData` If the provided data is not exactly 8 byte long.
     */
    func convertToInt64(_ data: Data) throws -> Int64 {
        guard data.count == 8 else {
            throw SerializationError.invalidData
        }

        switch self {
        case .bigEndian:
            return Int64(bigEndian: data.withUnsafeBytes { $0.load(as: Int64.self) })
        case .littleEndian:
            return Int64(bigEndian: data.withUnsafeBytes { $0.load(as: Int64.self) })
        }
    }

    /**
     Converts the provided value into a double value.

     - Parameter data: The data to convert.
     - Returns: The converted `data` as a double.
     - Throws:
     - `SerializationError.invalidData` If the provided data is not exactly 8 byte long.
     */
    func convertToDouble(_ data: Data) throws -> Double {
        guard data.count == 8 else {
            throw SerializationError.invalidData
        }

        switch self {
        case .bigEndian:
            return Double(bitPattern: UInt64(bigEndian: data.withUnsafeBytes { $0.load(as: UInt64.self) }))
        case .littleEndian:
            return Double(bitPattern: UInt64(littleEndian: data.withUnsafeBytes { $0.load(as: UInt64.self) }))
        }
    }
}
