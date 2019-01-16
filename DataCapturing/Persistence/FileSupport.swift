//
//  FileSupport.swift
//  DataCapturing
//
//  Created by Team Cyface on 29.08.18.
//

import Foundation
import os.log

/**
 The protocol for writing accelerations to a file.
 
 - Author: Klemens Muthmann
 - Version: 2.0.0
 - Since: 2.0.0
 */
protocol FileSupport {

    /// The generic type of the data to store to a file.
    associatedtype Serializable
    /// The name of the file to store.
    var fileName: String { get }
    /// The file extension of the file to store.
    var fileExtension: String { get }

    /**
     Appends data to a file for a certain measurement.
     
     - Parameters:
     - serializable: The data to append.
     - to: The measurement to append the data to.
     - Throws: If accessing the data file has not been successful.
     - Returns: The local URL identifying the file to write to.
     */
    func write(serializable: Serializable, to measurement: Int64) throws -> URL
    func remove(from measurement: MeasurementMO) throws
}

extension FileSupport {

    /**
     Creates the path to a file containing data in the Cyface binary format.

     - Parameter for: The measurement to create the path to the data file for.
     - Returns: The path to the file as an URL.
     - Throws: On failure of creating the file at the required path.
     */
    fileprivate func path(for measurement: Int64) throws -> URL {
        let measurementIdentifier = measurement
        let root = "Application support"
        let measurementDirectory = "measurements"

        let measurementDirectoryPath = try FileManager.default.url(for: FileManager.SearchPathDirectory.libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(root).appendingPathComponent(measurementDirectory).appendingPathComponent(String(measurementIdentifier))
        try FileManager.default.createDirectory(at: measurementDirectoryPath, withIntermediateDirectories: true)

        let filePath = measurementDirectoryPath.appendingPathComponent(fileName).appendingPathExtension(fileExtension)
        if !FileManager.default.fileExists(atPath: filePath.path) {
            FileManager.default.createFile(atPath: filePath.path, contents: nil)
        }

        return filePath
    }

    func remove(from measurement: MeasurementMO) throws {
        let filePath = try path(for: measurement.identifier)
        let parent = filePath.deletingLastPathComponent()

        try FileManager.default.removeItem(at: filePath)

        // Remove the measurement folder if it is empty now.
        if parent.hasDirectoryPath {
            let contents = try FileManager.default.contentsOfDirectory(at: parent, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            if contents.isEmpty {
                try FileManager.default.removeItem(at: parent)
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
struct AccelerationsFile: FileSupport {

    let serializer = AccelerationSerializer()

    var fileName: String {
        return "accel"
    }

    var fileExtension: String {
        return "cyfa"
    }

    func write(serializable: [Acceleration], to measurement: Int64) throws -> URL {
        let accelerationData = try serializer.serialize(serializable: serializable)
        let accelerationFilePath = try path(for: measurement)

        let fileHandle = try FileHandle(forWritingTo: accelerationFilePath)
        defer { fileHandle.closeFile()}
        fileHandle.seekToEndOfFile()
        fileHandle.write(accelerationData)

        return accelerationFilePath
    }

    func load(from measurement: MeasurementMO) throws -> [Acceleration] {
        do {
            let fileHandle = try FileHandle(forReadingFrom: path(for: measurement.identifier))
            defer {fileHandle.closeFile()}
            let data = fileHandle.readDataToEndOfFile()
            return try serializer.deserialize(data: data, count: UInt32(measurement.accelerationsCount))
        } catch let error {
            throw FileSupportError.notReadable(cause: error)
        }
    }

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


    private static let logger = OSLog(subsystem: "de.cyface", category: "SDK")

    var fileName: String {
        return "m"
    }

    var fileExtension: String {
        return "cyf"
    }

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

public enum FileSupportError: Error {
    case notReadable(cause: Error)
}
