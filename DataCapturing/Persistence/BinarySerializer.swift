//
//  BinarySerializer.swift
//  DataCapturing
//
//  Created by Team Cyface on 27.02.18.
//

import Foundation
import DataCompression

/// The current version of the Cyface binary format.
let dataFormatVersion: UInt16 = 1

/**
 Enum used to specify the correct byte order. Apple uses little endian while Cyface uses big endian.

 ````
 case bigEndian
 case littleEndian
 ````
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
}

/**
 Protocol that must be fullfilled by a serializer to transform an object into the Cyface binary format.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 2.0.0
 */
protocol BinarySerializer {
    /// The type of the item to serialize.
    associatedtype Serializable

    /**
     Serializes the provided serializable into a Cyface binary format representation. This only works for supported object types such as `MeasurementMO`, ÀccelerationPointMO` and `GeoLocationMO`.

     - Parameter serializable: The object to serialize.
     - Returns: A binary format representation of the provided object.
     */
    func serialize(serializable: Serializable) -> Data
    /**
     Serializes the provided `measurement` and compresses the returned data.

     - Parameters:
     - measurement: The `measurement` to serialize.
     - Returns: The serialized measurement in the compressed Cyface binary format
     */
    func serializeCompressed(serializable: Serializable) -> Data
}

extension BinarySerializer {
    /**
     Serializes and compresses the provided serializable and returns the serialized variant.

     - Parameter serializable:
     - Returns: A compressed variant of the serialized data.
     */
    func serializeCompressed(serializable: Serializable) -> Data {
        let res = serialize(serializable: serializable)

        guard let compressed = res.deflate() else {
            fatalError("CyfaceBinaryFormatSerializer.serializeCompressed(\(serializable)): Unable to compress data.")
        }

        return compressed
    }
}

// MARK: - Protocol implementations
/*
 In contrast to Apples proposals, these are not implemented as structs but classes. The reason is that none of the implementations contain a state and I see absolutely no reason to copy stateless instances around all the time. Probably slows down everything.
 */

/**
 A serializer for measurements into the Cyface binary format represenation.

 - Author: Klemens Muthmann
 - Since: 2.0.0
 - Version: 1.0.0
 */
class MeasurementSerializer: BinarySerializer {
    /// Binds the Serializeable from the `BinarySerializer` protocol to a measurement.
    typealias Serializable = MeasurementMO

    /**
     Serializes the provided `measurement` into its Cyface Binary Format specification in the form:
     - 2 Bytes: Version of the file format.
     - 4 Bytes: Count of geo locations
     - 4 Bytes: Count of accelerations
     - 4 Bytes: Count of rotations (not used on iOS yet)
     - 4 Bytes: Count of directions (not used on iOS yet)

     - Parameter measurement: The measurement to serialize.
     */
    func serialize(serializable measurement: MeasurementMO) -> Data {
        let accelerations = measurement.accelerations
        let geoLocations = measurement.geoLocations

        var dataArray = [UInt8]()
        // add header
        let byteOrder = ByteOrder.bigEndian
        dataArray.append(contentsOf: byteOrder.convertToBytes(dataFormatVersion))
        dataArray.append(contentsOf: byteOrder.convertToBytes(UInt32(geoLocations.count)))
        dataArray.append(contentsOf: byteOrder.convertToBytes(UInt32(accelerations.count)))
        dataArray.append(contentsOf: byteOrder.convertToBytes(UInt32(0)))
        dataArray.append(contentsOf: byteOrder.convertToBytes(UInt32(0)))

        return Data(bytes: dataArray)
    }
}

/**
 A serializer for accelerations into the Cyface binary format representation

 - Author: Klemens Muthmann
 - Since: 2.0.0
 - Version: 1.0.0
 */
class AccelerationSerializer: BinarySerializer {
    /// Binds the Serializeable from the `BinarySerializer` protocol to an array of acceleration points.
    typealias Serializable = [AccelerationPointMO]

    /**
     Serializes an array of accelerations into binary format of the form:
     - 8 Bytes: timestamp as long
     - 8 Bytes: x as double
     - 8 Bytes: y as double
     - 8 Bytes: z as double

     - Parameter accelerations: The array of accelerations to serialize.
     - Returns: An array of serialized bytes.
     */
    func serialize(serializable accelerations: [AccelerationPointMO]) -> Data {
        var ret = [UInt8]()
        let byteOrder = ByteOrder.bigEndian

        for acceleration in accelerations {
            // 8 Bytes
            ret.append(contentsOf: byteOrder.convertToBytes(acceleration.timestamp))
            // 8 Bytes
            ret.append(contentsOf: byteOrder.convertToBytes(acceleration.ax.bitPattern))
            // 8 Bytes
            ret.append(contentsOf: byteOrder.convertToBytes(acceleration.ay.bitPattern))
            // 8 Bytes
            ret.append(contentsOf: byteOrder.convertToBytes(acceleration.az.bitPattern))
            // 32 Bytes
        }

        return Data(bytes: ret)
    }
}

/**
 A serializer for geo locations into the Cyface binary format representation

 - Author: Klemens Muthmann
 - Since: 2.0.0
 - Version: 1.0.0
 */
class GeoLocationSerializer: BinarySerializer {
    /// Binds the `Serializeble from the `BinarySerializer` protocol to an array of geo locations.
    typealias Serializable = [GeoLocationMO]

    /**
     Serializes an array of geo locations into binary format of the form:
     - 8 Bytes: timestamp as long
     - 8 Bytes: latitude as double
     - 8 Bytes: longitude as double
     - 8 Bytes: speed as double
     - 4 Bytes: accuracy as int

     - Parameter geoLocations: The array of locations to serialize.
     - Returns: An array of serialized bytes.
     */
    func serialize(serializable locations: [GeoLocationMO]) -> Data {
        var ret = [UInt8]()
        let byteOrder = ByteOrder.bigEndian

        for location in locations {
            // 8 Bytes
            let timestamp = location.timestamp
            ret.append(contentsOf: byteOrder.convertToBytes(timestamp))
            // 8 Bytes
            let latBitPattern = location.lat.bitPattern
            ret.append(contentsOf: byteOrder.convertToBytes(latBitPattern))
            // 8 Bytes
            let lonBitPattern = location.lon.bitPattern
            ret.append(contentsOf: byteOrder.convertToBytes(lonBitPattern))
            // 8 Bytes
            let speedBitPattern = location.speed.bitPattern
            ret.append(contentsOf: byteOrder.convertToBytes(speedBitPattern))
            // 4 Bytes
            let accuracy = UInt32(location.accuracy*100)
            ret.append(contentsOf: byteOrder.convertToBytes(accuracy))
            // = 36 Bytes
        }

        return Data(bytes: ret)
    }
}

/**
 Transforms measurement data into the Cyface binary format used for transmission via the network.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 1.0.0
 */
class CyfaceBinaryFormatSerializer {
    /// Serializer to transform measurement objects
    let measurementSerializer = MeasurementSerializer()
    /// Serializer to transform acceleration objects
    let accelerationsSerializer = AccelerationSerializer()
    /// Serializer to transform geo location objects
    let geoLocationsSerializer = GeoLocationSerializer()
    /**
     Serializes the provided `measurement` and compresses the returned data.

     - Parameters:
     - measurement: The `measurement` to serialize.
     - Returns: The serialized measurement in the compressed Cyface binary format
     - Throws: `SerializationError.compressionFailed` if compression was not successful.
     */
    func serializeCompressed(_ measurement: MeasurementMO) throws -> Data {
        let res = serialize(measurement)

        guard let compressed = res.deflate() else {
            throw SerializationError.compressionFailed
        }

        return compressed
    }

    /**
     Serializes the provided measurement into the Cyface binary format.

     - Parameter measurement: The `measurement` to serialize.
     - Returns: The serialized measurement in Cyface binary format.
     */
    func serialize(_ measurement: MeasurementMO) -> Data {
        let serializedMeasurement = measurementSerializer.serialize(serializable: measurement)
        let serializedGeoLocations = geoLocationsSerializer.serialize(serializable: measurement.geoLocations)
        let serializedAccelerations = accelerationsSerializer.serialize(serializable: measurement.accelerations)

        var ret = Data()
        ret.append(serializedMeasurement)
        ret.append(serializedGeoLocations)
        ret.append(serializedAccelerations)

        return ret
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
 ````
 */
enum SerializationError: Error {
    /// Thrown if compression of serialized data was not successful.
    case compressionFailed
}
