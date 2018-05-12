//
//  CyfaceBinaryFormatSerializer.swift
//  DataCapturing
//
//  Created by Team Cyface on 27.02.18.
//

import Foundation
import DataCompression

/**
 Transforms measurement data into the Cyface binary format used for transmission via the network.
 
 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 1.0.0
 */
class CyfaceBinaryFormatSerializer {
    
    /**
     The current version of the Cyface binary format.
     */
    private static let dataFormatVersion: UInt16 = 1
    
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
    }
    
    /**
     Converts the provided value into a byte representation.
     
     - Parameters:
     - value: The value to convert to a byte representation.
     - inOrder: The byte order to use. Apple usually uses little endian, while the Cyface binary format is currently in big endian format, because that is the standard on Android and in the backend system.
     - Returns: An array of bytes, representing the provided value.
     */
    func convertToBytes<T: BinaryInteger>(_ value: T, inOrder order: ByteOrder) -> [UInt8] {
        let ret = value.extractBytes()
        
        return order == .bigEndian ? ret.reversed() : ret
    }
    
    /**
     Serializes the provided `measurement` and compresses the returned data.
     
     - Parameters:
     - measurement: The `measurement` to serialize.
     - Returns: The serialized measurement in the compressed Cyface binary format
     */
    func serializeCompressed(_ measurement: MeasurementMO) -> Data {
        let res = serialize(measurement)
        
        guard let compressed = res.deflate() else {
            fatalError("CyfaceBinaryFormatSerializer.serializeCompressed(\(measurement.identifier)): Unable to compress data.")
        }
        
        return compressed
    }
    
    /**
     Serializes the provided measurement into the Cyface binary format.
     
     - Parameter measurement: The `measurement` to serialize.
     - Returns: The serialized measurement in Cyface binary format.
     */
    func serialize(_ measurement: MeasurementMO) -> Data {
        let accelerations = measurement.accelerations ?? []
        let geoLocations = measurement.geoLocations ?? []
        
        var dataArray = [UInt8]()
        // add header
        let version = CyfaceBinaryFormatSerializer.dataFormatVersion
        dataArray.append(contentsOf: convertToBytes(version, inOrder: .bigEndian))
        dataArray.append(contentsOf: convertToBytes(UInt32(geoLocations.count), inOrder: .bigEndian))
        dataArray.append(contentsOf: convertToBytes(UInt32(accelerations.count), inOrder: .bigEndian))
        dataArray.append(contentsOf: convertToBytes(UInt32(0), inOrder: .bigEndian))
        dataArray.append(contentsOf: convertToBytes(UInt32(0), inOrder: .bigEndian))
        
        let serializedGeoLocations = serialize(geoLocations: geoLocations)
        dataArray.append(contentsOf: serializedGeoLocations)
        let serializedAccelerations = serialize(accelerations: accelerations)
        dataArray.append(contentsOf: serializedAccelerations)
        
        return Data(bytes: dataArray)
    }
    
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
    private func serialize(geoLocations locations: [GeoLocationMO]) -> [UInt8] {
        var ret = [UInt8]()
        
        for location in locations {
            // 8 Bytes
            ret.append(contentsOf: convertToBytes(location.timestamp, inOrder: .bigEndian))
            // 8 Bytes
            ret.append(contentsOf: convertToBytes(location.lat.bitPattern, inOrder: .bigEndian))
            // 8 Bytes
            ret.append(contentsOf: convertToBytes(location.lon.bitPattern, inOrder: .bigEndian))
            // 8 Bytes
            ret.append(contentsOf: convertToBytes(location.speed.bitPattern, inOrder: .bigEndian))
            // 4 Bytes
            ret.append(contentsOf: convertToBytes(UInt32(location.accuracy*100), inOrder: .bigEndian))
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
            buffer = buffer >> 7
        }
        
        return ret
    }
}
