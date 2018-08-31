//
//  CyfaceBinaryFormatSerializer.swift
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

protocol BinarySerializer {
    associatedtype Serializable
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

    func serializeCompressed(serializable: Serializable) -> Data {
        let res = serialize(serializable: serializable)

        guard let compressed = res.deflate() else {
            fatalError("CyfaceBinaryFormatSerializer.serializeCompressed(\(serializable)): Unable to compress data.")
        }

        return compressed
    }
}

class MeasurementSerializer: BinarySerializer {
    typealias Serializable = MeasurementMO

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

        /*let serializedGeoLocations = serialize(geoLocations: geoLocations)
        dataArray.append(contentsOf: serializedGeoLocations)
        let serializedAccelerations = serialize(accelerations: accelerations)
        dataArray.append(contentsOf: serializedAccelerations)*/

        return Data(bytes: dataArray)
    }
}

class AccelerationSerializer: BinarySerializer {
    typealias Serializable = [AccelerationPointMO]

    func serialize(serializable accelerations: [AccelerationPointMO]) -> Data{
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

class GeoLocationSerializer: BinarySerializer {
    typealias Serializable = [GeoLocationMO]

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

    let measurementSerializer = MeasurementSerializer()
    let accelerationsSerializer = AccelerationSerializer()
    let geoLocationsSerializer = GeoLocationSerializer()
    /**
     Serializes the provided `measurement` and compresses the returned data.

     - Parameters:
     - measurement: The `measurement` to serialize.
     - Returns: The serialized measurement in the compressed Cyface binary format
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
/*
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
    func serialize(geoLocations locations: [GeoLocationMO]) -> [UInt8] {
        var ret = [UInt8]()

        for location in locations {
            // 8 Bytes
            let timestamp = location.timestamp
            ret.append(contentsOf: convertToBytes(timestamp, inOrder: .bigEndian))
            // 8 Bytes
            let latBitPattern = location.lat.bitPattern
            ret.append(contentsOf: convertToBytes(latBitPattern, inOrder: .bigEndian))
            // 8 Bytes
            let lonBitPattern = location.lon.bitPattern
            ret.append(contentsOf: convertToBytes(lonBitPattern, inOrder: .bigEndian))
            // 8 Bytes
            let speedBitPattern = location.speed.bitPattern
            ret.append(contentsOf: convertToBytes(speedBitPattern, inOrder: .bigEndian))
            // 4 Bytes
            let accuracy = UInt32(location.accuracy*100)
            ret.append(contentsOf: convertToBytes(accuracy, inOrder: .bigEndian))
            // = 36 Bytes
        }

        return ret
    }

    /**
     Serializes an array of accelerations into binary format of the form:
     - 8 Bytes: timestamp as long
     - 8 Bytes: x as double
     - 8 Bytes: y as double
     - 8 Bytes: z as double

     - Parameter accelerations: The array of accelerations to serialize.
     - Returns: An array of serialized bytes.
     */
    private func serialize(accelerations: [AccelerationPointMO]) -> [UInt8] {
        var ret = [UInt8]()

        for acceleration in accelerations {
            // 8 Bytes
            ret.append(contentsOf: convertToBytes(acceleration.timestamp, inOrder: .bigEndian))
            // 8 Bytes
            ret.append(contentsOf: convertToBytes(acceleration.ax.bitPattern, inOrder: .bigEndian))
            // 8 Bytes
            ret.append(contentsOf: convertToBytes(acceleration.ay.bitPattern, inOrder: .bigEndian))
            // 8 Bytes
            ret.append(contentsOf: convertToBytes(acceleration.az.bitPattern, inOrder: .bigEndian))
            // 32 Bytes
        }

        return ret
    }*/
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

enum SerializationError: Error {
    case compressionFailed
}
