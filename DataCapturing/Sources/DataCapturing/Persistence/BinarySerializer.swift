/*
 * Copyright 2018-2024 Cyface GmbH
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
let dataFormatVersion: UInt16 = 3
/// The current version of the Cyface binary format in binary data form.
let dataFormatVersionBytes = withUnsafeBytes(of: dataFormatVersion.bigEndian) {
    Data($0)
}

/**
 Protocol that must be fullfilled by a serializer to transform an object into the Cyface binary format. The associated type `Serializable` is a placeholder for the type of object to serialize and deserialize.
 
 - Author: Klemens Muthmann
 - Version: 1.1.0
 - Since: 2.0.0
 */
public protocol BinarySerializer {

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
    public func serializeCompressed(serializable: Serializable) throws -> Data {
        let res = try serialize(serializable: serializable)

        guard let compressed = res.deflate() else {
            os_log("Unable to compress data.",
                   log: OSLog.init(subsystem: "BinarySerializer",
                                   category: "de.cyface"),
                   type: .error)
            throw SerializationError.compressionFailed(data: res)
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
    /// The number of centimeters in a meter.
    static let centimetersInAMeter = 100.0
    /// The targeted amount of places after the comma to use for storing geo locations.
    static let geoLocationAccuracy = 6

    /**
     Serializes the provided `measurement` into its Cyface Binary Format specification in the form:
     - 2 Bytes: Version of the file format.
     - 4 Bytes: Count of geo locations
     - 4 Bytes: Count of accelerations
     - 4 Bytes: Count of rotations (not used on iOS yet)
     - 4 Bytes: Count of directions (not used on iOS yet)
     
     - Parameter serializable: The measurement to serialize.
     - Throws: if either converting the provided data or reading the sensor values fails.
     */
    public func serialize(serializable measurement: FinishedMeasurement) throws -> Data {
        var protosMeasurement = De_Cyface_Protos_Model_MeasurementBytes()
        protosMeasurement.formatVersion = UInt32(dataFormatVersion)
        protosMeasurement.events = serialize(events: measurement.events)
        protosMeasurement.locationRecords = De_Cyface_Protos_Model_LocationRecords()

        let firstTimestamp = DiffValue(start: Int64(0))
        let firstAccuracy = DiffValue(start: Int32(0))
        let firstLatitude = DiffValue(start: Int32(0))
        let firstLongitude = DiffValue(start: Int32(0))
        let firstSpeed = DiffValue(start: Int32(0))
        protosMeasurement.locationRecords.timestamp = []
        protosMeasurement.locationRecords.speed = []
        protosMeasurement.locationRecords.latitude = []
        protosMeasurement.locationRecords.longitude = []
        protosMeasurement.locationRecords.accuracy = []

        var records = protosMeasurement.locationRecords
        for location in measurement.tracks.flatMap({track in track.locations}) {
            let timestamp = convertToUtcTimestamp(date: location.time)
            let accuracy = location.accuracy
            let latitude = location.latitude
            let longitude = location.longitude
            let speed = location.speed

            do {
                let diffTimestamp = try firstTimestamp.diff(value: Int64(timestamp))
                records.timestamp.append(diffTimestamp)
            } catch {
                throw SerializationError.nonSerializableLocationTimestamp(cause: error, timestamp: timestamp)
            }
            do {
                let diffAccuracy = try firstAccuracy.diff(value: Int32(accuracy * MeasurementSerializer.centimetersInAMeter))
                records.accuracy.append(diffAccuracy)
            } catch {
                throw SerializationError.nonSerializableAccuracy(cause: error, accuracy: accuracy)
            }
            do {
                let diffLatitude = try firstLatitude.diff(value: convert(coordinate: latitude))
                records.latitude.append(diffLatitude)
            } catch {
                throw SerializationError.nonSerializableLatitude(cause: error, latitude: latitude)
            }
            do {
                let diffLongitude = try firstLongitude.diff(value: convert(coordinate: longitude))
                records.longitude.append(diffLongitude)
            } catch {
                throw SerializationError.nonSerializableLongitude(cause: error, longitude: longitude)
            }
            do {
                let diffSpeed = try firstSpeed.diff(value: Int32(speed * MeasurementSerializer.centimetersInAMeter))
                records.speed.append(diffSpeed)
            } catch {
                throw SerializationError.nonSerializableSpeed(cause: error, speed: speed)
            }
        }
        protosMeasurement.locationRecords = records

        protosMeasurement.accelerationsBinary = measurement.accelerationData
        protosMeasurement.directionsBinary = measurement.directionData
        protosMeasurement.rotationsBinary = measurement.rotationData
        let serializedData = try protosMeasurement.serializedData()
        var ret = Data(dataFormatVersionBytes)
        ret.append(serializedData)

        return ret
    }

    /// Serializes the provided `Event` instances to a Protobuf event type.
    private func serialize(events: [Event]) -> [De_Cyface_Protos_Model_Event] {
        var ret = [De_Cyface_Protos_Model_Event]()
        for event in events {
            ret.append(De_Cyface_Protos_Model_Event.with {
                $0.timestamp = convertToUtcTimestamp(date: event.time)
                if let value = event.value {
                    $0.value = value
                }
                switch event.type {
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

    /**
      Transforms a double to a 32 bit integer.

      This is achieved by moving the comma `geoLocationAccuracy` places to the right and ommiting any further places after that.
     */
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
 - Version: 2.0.1
 - Note: This class was called `AccelerationSerializer` in SDK version prior to 6.0.0.
 */
public class SensorValueSerializer: BinarySerializer {
    /// A constant used to convert between millimeters and meters.
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
    public func serialize(serializable values: [SensorValue]) throws -> Data {
        guard !values.isEmpty else {
            throw BinarySerializationError.emptyData
        }
        let timestampDiffValue = DiffValue(start: Int64(0))
        let xDiffValue = DiffValue(start: Int32(0))
        let yDiffValue = DiffValue(start: Int32(0))
        let zDiffValue = DiffValue(start: Int32(0))

        var timestamps = [Int64]()
        var xValues = [Int32]()
        var yValues = [Int32]()
        var zValues = [Int32]()
        for valueIndex in values.indices {
            let timestamp = values[valueIndex].timestamp
            let xValue = values[valueIndex].x
            let yValue = values[valueIndex].y
            let zValue = values[valueIndex].z
            let utcTimestamp = convertToUtcTimestamp(date: timestamp)
            do {
                timestamps.append(try timestampDiffValue.diff(value: Int64(utcTimestamp)))
            } catch {
                throw SerializationError.nonSerializableSensorValueTimestamp(cause: error, timestamp: timestamp)
            }
            do {
                xValues.append(try xDiffValue.diff(value: Int32(xValue*SensorValueSerializer.millimetersInAMeter)))
            } catch {
                throw SerializationError.nonSerializableXValue(cause: error, value: xValue)
            }
            do {
                yValues.append(try yDiffValue.diff(value: Int32(yValue*SensorValueSerializer.millimetersInAMeter)))
            } catch {
                throw SerializationError.nonSerializableYValue(cause: error, value: yValue)
            }
            do {
                zValues.append(try zDiffValue.diff(value: Int32(zValue*SensorValueSerializer.millimetersInAMeter)))
            } catch {
                throw SerializationError.nonSerializableZValue(cause: error, value: zValue)
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

            let timestampUnDiff = DiffValue(start: Int64(0))
            let axUnDiff = DiffValue(start: Int32(0))
            let ayUnDiff = DiffValue(start: Int32(0))
            let azUnDiff = DiffValue(start: Int32(0))

            for batch in deserializedValues.accelerations {
                for accelerationsIndex in batch.timestamp.indices {
                    let timestamp = try timestampUnDiff.undiff(value: batch.timestamp[accelerationsIndex])
                    let ax = Double(try axUnDiff.undiff(value: batch.x[accelerationsIndex]))/SensorValueSerializer.millimetersInAMeter
                    let ay = Double(try ayUnDiff.undiff(value: batch.y[accelerationsIndex]))/SensorValueSerializer.millimetersInAMeter
                    let az = Double(try azUnDiff.undiff(value: batch.z[accelerationsIndex]))/SensorValueSerializer.millimetersInAMeter

                    let value = SensorValue(timestamp: Date(timeIntervalSince1970: Double(timestamp)/1_000), x: ax, y: ay, z: az)
                    ret.append(value)
                }
            }

            return ret
        }

    /**
     An enumeration of errors happening during the serialization of Cyface data to the binary format.

     - author: Klemens Muthmann
     - version: 1.0.0
     */
    enum BinarySerializationError: Error {
        /// Thrown if no data was provided, where some was expected.
        case emptyData
    }
}

/**
 A calculator for differential encoding of an integer time series.

 By starting from an initial values this class provides an algorithm, that always gives you the next differential in a time series of values. Since this allows to store smaller values, less bytes can be used per value.

 - author: Klemens Muthmann
 - version: 1.0.0
 */
class DiffValue<T: FixedWidthInteger> {
    /// The value to calculate the differential for.
    var previousValue: T

    /// Initialize this `DiffValue` with a start value.
    init(start: T) {
        previousValue = start
    }

    /// Calculate the diff between the last and the provided value.
    func diff(value: T) throws -> T {
        let ret = value.subtractingReportingOverflow(previousValue)
        guard !ret.overflow else {
            throw DiffValueError.diffOverflow(minuend: value, subtrahend: previousValue)
        }
        previousValue = value
        return ret.partialValue
    }

    /// Calculate the sum between the last and the provided value.
    func undiff(value: T) throws -> T {
        let ret = previousValue.addingReportingOverflow(value)
        guard !ret.overflow else {
            throw DiffValueError.sumOverflow(firstSummand: previousValue, secondSummand: value)
        }
        previousValue = ret.partialValue
        return ret.partialValue
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
