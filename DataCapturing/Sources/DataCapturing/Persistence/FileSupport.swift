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

import Foundation
import os.log

/**
 The protocol for writing accelerations to a file.
 
 - Author: Klemens Muthmann
 - Version: 3.0.0
 - Since: 2.0.0
 */
protocol FileSupport {

    // MARK: - Properties

    /// The generic type of the data to store to a file.
    associatedtype Serializable
    /// The name of the file to store.
    var fileName: String { get }
    /// The file extension of the file to store.
    var fileExtension: String { get }
    var measurement: MeasurementMO { get }

    // MARK: - Methods
    /**
     Appends data to a file for a certain measurement.
     
     - Parameters:
        - serializable: The data to append.
     - Throws: If accessing the data file has not been successful.
     - Returns: The local URL identifying the file to write to.
     */
    func write(serializable: Serializable) throws -> URL
    /**
     Removes the file for the provided `FinishedMeasurement` instance.
     */
    func delete() throws
}

// MARK: - Implementation

extension FileSupport {

    /**
     Creates the path to a file containing data in the Cyface binary format.

     - Parameter for: The measurement to create the path to the data file for.
     - Returns: The path to the file as an URL.
     - Throws: Some internal file system error on failure of creating the file at the required path.
     */
    fileprivate func path() throws -> URL {
        let measurementIdentifier = measurement.identifier
        let root = "Application Support"
        let measurementDirectory = "measurements"
        let fileManager = FileManager.default
        let libraryDirectory = FileManager.SearchPathDirectory.libraryDirectory
        let libraryDirectoryUrl = try fileManager.url(for: libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

        let measurementDirectoryPath = libraryDirectoryUrl
            .appendingPathComponent(root)
            .appendingPathComponent(measurementDirectory)
            .appendingPathComponent(String(measurementIdentifier))
        try fileManager.createDirectory(at: measurementDirectoryPath, withIntermediateDirectories: true)

        let filePath = measurementDirectoryPath.appendingPathComponent(fileName).appendingPathExtension(fileExtension)
        if !fileManager.fileExists(atPath: filePath.path) {
            fileManager.createFile(atPath: filePath.path, contents: nil)
        }

        return filePath
    }

    /**
     Removes the data file for the provided measurement. If this was the last or only data file it also deletes the folder containing the files for the measurement.

     - Parameter from: The measurement to delete the data from.
     - Throws: Some internal file system error on failure of creating the file at the required path.
     */
    func delete() throws {
        let filePath = try path()
        let parent = filePath.deletingLastPathComponent()
        let fileManager = FileManager.default

        if try filePath.checkResourceIsReachable() {
            try fileManager.removeItem(at: filePath)
        }

        // Remove the measurement folder if it is empty now.
        if parent.hasDirectoryPath {
            let contents = try fileManager.contentsOfDirectory(at: parent, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            if contents.isEmpty {
                try fileManager.removeItem(at: parent)
            }
        }
    }
}

/**
 Struct implementing the `FileSupport` protocol to store sensor values to a file in Cyface binary format.
 
 - Author: Klemens Muthmann
 - Version:4.0.0
 - Since: 2.0.0
 - Note: This class was called `AccelerationsFile` prior to SDK version 6.0.0.
 */
public struct SensorValueFile: FileSupport {

    // MARK: - Properties

    /// A serializer to transform between sensor values and the Cyface Binary Format.
    let serializer = SensorValueSerializer()

    /// The file name for the file containing the sensor values for one measurement.
    var fileName: String {
        return "accel"
    }

    /// File extension used for files containing accelerations.
    var fileExtension: String {
        return fileType.fileExtension
    }
    let fileType: SensorValueFileType
    let measurement: MeasurementMO

    /// Public initializer for external systems to access sensor value data.
    public init(measurement: MeasurementMO, fileType: SensorValueFileType) {
        self.fileType = fileType
        self.measurement = measurement
    }

    // MARK: - Methods

    /**
     Writes the provided sensor values to the provided measurement.
     

     - Parameters:
        - serializable: The array of sensor values to write.
     - Returns: The file system URL of the file that was written to.
     - Throws: Some internal file system error on failure of creating the file at the required path.
     - Throws: `BinarySerializationError.emptyData` if the provided `serializable` array is empty.
     - Throws: `BinaryEncodingError` if encoding fails.
     */
    func write(serializable: [SensorValue]) throws -> URL {
        let sensorValueData = try serializer.serialize(serializable: serializable)
        let sensorValueFilePath = try path()

        let fileHandle = try FileHandle(forWritingTo: sensorValueFilePath)
        defer { fileHandle.closeFile()}
        guard FileManager.default.isWritableFile(atPath: sensorValueFilePath.path) else {
            fatalError("Unable to write sensor data since file is not writable!")
        }
        fileHandle.seekToEndOfFile()
        fileHandle.write(sensorValueData)

        return sensorValueFilePath
    }

    /**
     Loads all sensor values from the provided measurement. This accesses the file system to get the data from the local sensor value storage file.

     - Throws: If the file containing the sensor values was not readable.
     - Returns: An array of all the sensor values from the provided measurement.
    */
    public func load() throws -> [SensorValue] {
        do {
            let fileHandle = try FileHandle(forReadingFrom: path())
            defer {fileHandle.closeFile()}
            let data = fileHandle.readDataToEndOfFile()
            return try serializer.deserialize(data: data)
        } catch let error {
            throw FileSupportError.notReadable(cause: error)
        }
    }

    /**
     Provides the binary data for the sensor values of the provided measurement.

     - Returns: The serialized sensor values in Cyface Binary Format.
     - Throws:
        - `FileSupportError.notReadable` If the data file was not readable.
        - Some unspecified undocumented file system error if file was not accessible.
    */
    func data() throws -> Data {
        do {
            let fileHandle = try FileHandle(forReadingFrom: path())
            defer {fileHandle.closeFile()}
            return fileHandle.readDataToEndOfFile()
        } catch let error {
            throw FileSupportError.notReadable(cause: error)
        }
    }
}

/**
 Struct implementing the `FileSupport` protocol to serialize whole measurements to a file in Cyface binary format.

 - Author: Klemens Muthmann
 - Version:3.0.0
 - Since: 2.0.0
 */
public struct MeasurementFile: FileSupport {
    typealias Serializable = FinishedMeasurement

    // MARK: - Properties

    /// The logger used by objects of this class.
    private static let logger = OSLog(subsystem: "de.cyface", category: "SDK")

    /// The file name used for measurement files.
    var fileName: String {
        return "m"
    }

    /// File extension used for measurement files.
    var fileExtension: String {
        return "cyf"
    }
    let measurement: MeasurementMO

    // MARK: - Methods

    /**
     Write a file containing a serialized measurement in Cyface Binary Format, to the local file system data storage.

     - Returns: A file system URL pointing to the written file.
     - Throws: `SerializationError.missingData` If no track data was found.
     - Throws: `SerializationError.invalidData` If the database provided inconsistent and wrongly typed data. Something is seriously wrong in these cases.
     - Throws: `FileSupportError.notReadable` If the data file was not readable.
     - Throws: Some unspecified undocumented file system error if file was not accessible.
    */
    func write(serializable: FinishedMeasurement) throws -> URL {
        let measurementData = try data(serializable: serializable)
        let measurementFilePath = try path()

        if let measurementData = measurementData {
            let measurementFileHandle = try FileHandle(forWritingTo: measurementFilePath)
            defer { measurementFileHandle.closeFile() }
            measurementFileHandle.write(measurementData)
        }

        return measurementFilePath
    }

    /**
     Creates a data representation from some `Measurement` object.

     - Parameter from: A valid object to create a data in Cyface binary format representation for.
     - Returns: The data in the Cyface binary format.
     - Throws: `SerializationError.missingData` If no track data was found.
     - Throws: `SerializationError.invalidData` If the database provided inconsistent and wrongly typed data. Something is seriously wrong in these cases.
     - Throws: `FileSupportError.notReadable` If the data to write could not be read from the database.
     - Throws: Some unspecified undocumented file system error if file was not accessible.
     */
    func data(serializable: FinishedMeasurement) throws -> Data? {
        let serializer = MeasurementSerializer()

        do {
            return try serializer.serializeCompressed(serializable: serializable)
        } catch {
            throw FileSupportError.notReadable(cause: error)
        }
    }
}

/**
Errors created by the Cyface SDK associated with accessing the file system.

```
case notReadable
```

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 2.0.0
 */
public enum FileSupportError: Error {
    /**
     This error is thrown if the file system was not readable.

     - cause: Another error, from system level, providing more detailed information.
     */
    case notReadable(cause: Error)
}

/**
 One type of a sensor value file, such as a file for accelerations, rotations or directions.
 This class may not be instantiated directly.
 The only valid instances are provided as static properties.

 - Author: Klemens Muthmann
 - Version: 2.0.0
 - Since: 6.0.0
 */
public class SensorValueFileType {
    /// A file type for acceleration files.
    public static let accelerationValueType = SensorValueFileType(
        fileExtension: "cyfa")
    /// A file type for rotation files.
    public static let rotationValueType = SensorValueFileType(
        fileExtension: "cyfr")
    /// A file type for direction files.
    public static let directionValueType = SensorValueFileType(
        fileExtension: "cyfd")

    /// The file extension of the represented file type.
    public let fileExtension: String

    /**
     Creates a new completely initiailized `SensorValueFileType`.
     This should never be called, since the only valid instances are pregenerated.

     - Parameters:
        - fileExtension: The file extension of the represented file type.
     */
    private init(fileExtension: String) {
        self.fileExtension = fileExtension
    }
}
