/*
 * Copyright 2018 Cyface GmbH
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
 - Version: 2.0.0
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

    // MARK: - Methods
    /**
     Appends data to a file for a certain measurement.
     
     - Parameters:
     - serializable: The data to append.
     - to: The measurement to append the data to.
     - Throws: If accessing the data file has not been successful.
     - Returns: The local URL identifying the file to write to.
     */
    func write(serializable: Serializable, to measurement: Int64) throws -> URL
    /**
     Removes the file for the provided `MeasurementMO` instance.
     */
    func remove(from measurement: MeasurementMO) throws
}

// MARK: - Implementation

extension FileSupport {

    /**
     Creates the path to a file containing data in the Cyface binary format.

     - Parameter for: The measurement to create the path to the data file for.
     - Returns: The path to the file as an URL.
     - Throws: On failure of creating the file at the required path.
     */
    fileprivate func path(for measurement: Int64) throws -> URL {
        let measurementIdentifier = measurement
        let root = "Application Support"
        let measurementDirectory = "measurements"
        let fileManager = FileManager.default
        let libraryDirectory = FileManager.SearchPathDirectory.libraryDirectory
        let libraryDirectoryUrl = try fileManager.url(for: libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

        let measurementDirectoryPath = libraryDirectoryUrl.appendingPathComponent(root).appendingPathComponent(measurementDirectory).appendingPathComponent(String(measurementIdentifier))
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
     - Throws: If reading or writing the file system failed.
     */
    func remove(from measurement: MeasurementMO) throws {
        let filePath = try path(for: measurement.identifier)
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
 Struct implementing the `FileSupport` protocol to store accelerations to a file in Cyface binary format.
 
 - Author: Klemens Muthmann
 - Version: 2.0.0
 - Since: 2.0.0
 */
public struct AccelerationsFile: FileSupport {

    // MARK: - Properties

    /// A serializer to transform between `Acceleration` instances and the Cyface Binary Format.
    let serializer = AccelerationSerializer()

    /// The file name for the file containing the acceleration values for one measurement.
    var fileName: String {
        return "accel"
    }

    /// File extension used for files containing accelerations.
    var fileExtension: String {
        return "cyfa"
    }

    /// Public initializer for external systems to access acceleration data.
    public init() {
        // Nothing to do here
    }

    // MARK: - Methods

    /**
     Writes the provided accelerations to the provided measurement.

     - Parameters:
     - serializable: The array of `Acceleration` instances to write.
     - to: The measurement to write the accelerations to.
     - Throws: If accessing the file system for reading or writing was not successful.
     - Returns: The file system URL of the file that was written to.
     */
    func write(serializable: [Acceleration], to measurement: Int64) throws -> URL {
        let accelerationData = try serializer.serialize(serializable: serializable)
        let accelerationFilePath = try path(for: measurement)

        let fileHandle = try FileHandle(forWritingTo: accelerationFilePath)
        defer { fileHandle.closeFile()}
        fileHandle.seekToEndOfFile()
        fileHandle.write(accelerationData)

        return accelerationFilePath
    }

    /**
     Loads all `Acceleration` instances from the provided measurement. This accesses the file system to get the data from the local acceleration storage file.

     - Parameter from: The measurement to load the accelerations from.
     - Throws: If the file containing the accelerations was not readable.
     - Returns: An array of all the acceleration value from the provided measurement.
    */
    public func load(from measurement: MeasurementMO) throws -> [Acceleration] {
        do {
            let fileHandle = try FileHandle(forReadingFrom: path(for: measurement.identifier))
            defer {fileHandle.closeFile()}
            let data = fileHandle.readDataToEndOfFile()
            return try serializer.deserialize(data: data, count: UInt32(measurement.accelerationsCount))
        } catch let error {
            throw FileSupportError.notReadable(cause: error)
        }
    }

    /**
     Provides the binary data for the acceleration values of the provided measurement.

     - Parameter for: The measurement to provide data for.
     - Throws: If the file storing the accelerations was not readable.
     - Returns: The serialized accelerations in Cyface Binary Format.
    */
    func data(for measurement: MeasurementMO) throws -> Data {
        do {
            let fileHandle = try FileHandle(forReadingFrom: path(for: measurement.identifier))
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
 - Version: 2.0.0
 - Since: 2.0.0
 */
struct MeasurementFile: FileSupport {

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

    // MARK: - Methods

    /**
     Write a file containing a serialized measurement in Cyface Binary Format, to the local file system data storage.

     - Parameters:
     - serializable: The measurement to write.
     - to: The measurement to write to.
     - Throws: In case the file system was not accessible for reading or writing.
     - Returns: A file system URL pointing to the written file.
    */
    func write(serializable: MeasurementMO, to measurement: Int64) throws -> URL {
        let measurementData = try data(from: serializable)
        let measurementFilePath = try path(for: measurement)

        if let measurementData = measurementData {
            let measurementFileHandle = try FileHandle(forWritingTo: measurementFilePath)
            defer { measurementFileHandle.closeFile() }
            measurementFileHandle.write(measurementData)
        }

        return measurementFilePath
    }

    /**
     Creates a data representation from some `MeasurementMO` object.

     - Parameter from: A valid object to create a data in Cyface binary format representation for.
     - Throws: If part of the required information was not accessible.
     - Returns: The data in the Cyface binary format.
     */
    func data(from serializable: MeasurementMO) throws -> Data? {
        let serializer = CyfaceBinaryFormatSerializer()

        return try serializer.serialize(serializable)
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
