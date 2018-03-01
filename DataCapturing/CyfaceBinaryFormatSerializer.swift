//
//  CyfaceBinaryFormatSerializer.swift
//  DataCapturing
//
//  Created by Team Cyface on 27.02.18.
//

import Foundation
import DataCompression

class CyfaceBinaryFormatSerializer {
    
    private static let DATA_FORMAT_VERSION: UInt16 = 1
    
    enum ByteOrder {
        case bigEndian
        case littleEndian
    }
    
    func convertToBytes<T: BinaryInteger>(_ value: T, inOrder order: ByteOrder) -> [UInt8] {
        let ret = value.extractBytes()
        
        return order == .bigEndian ? ret.reversed() : ret
    }
    
    func serializeCompressed(_ measurement: MeasurementMO) -> Data {
        let res = serialize(measurement)
        
        guard let compressed = res.deflate() else {
            fatalError("CyfaceBinaryFormatSerializer.serializeCompressed(\(measurement.identifier)): Unable to compress data.")
        }
        
        return compressed
    }
    
    func serialize(_ measurement: MeasurementMO) -> Data {
        let accelerations = measurement.accelerations == nil ? [] : measurement.accelerations!
        let geoLocations = measurement.geoLocations == nil ? [] : measurement.geoLocations!
        
        var dataArray = [UInt8]()
        // add header
        let version = CyfaceBinaryFormatSerializer.DATA_FORMAT_VERSION
        dataArray.append(contentsOf: convertToBytes(version,inOrder:.bigEndian))
        dataArray.append(contentsOf: convertToBytes(UInt32(geoLocations.count), inOrder:.bigEndian))
        dataArray.append(contentsOf: convertToBytes(UInt32(accelerations.count), inOrder: .bigEndian))
        dataArray.append(contentsOf: convertToBytes(UInt32(0), inOrder: .bigEndian))
        dataArray.append(contentsOf: convertToBytes(UInt32(0), inOrder: .bigEndian))
        
        let serializedGeoLocations = serialize(geoLocations: geoLocations.array as! [GeoLocationMO])
        dataArray.append(contentsOf: serializedGeoLocations)
        let serializedAccelerations = serialize(accelerations: accelerations.array as! [AccelerationPointMO])
        dataArray.append(contentsOf: serializedAccelerations)
        
        return Data(bytes: dataArray)
    }
    
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


extension BinaryInteger {
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
