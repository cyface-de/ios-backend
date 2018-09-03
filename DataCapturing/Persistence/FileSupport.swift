//
//  FileSupport.swift
//  DataCapturing
//
//  Created by Team Cyface on 29.08.18.
//

import Foundation

/**
 The protocol for writing accelerations to a file.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 2.0.0
 */
protocol FileSupport {
    /**
     Creates the path to a file containing acceleration points in the Cyface binary format.

     - Parameter for: The measurement to create the path to the acceleration file for.
     - Returns: The path to the file as an URL.
     - Throws: On failure of creating the file at the required path.
    */
    func path(for measurement: Int64) throws -> URL
    /**
     Appends acceleration points to a file for a certain measurement.

     - Parameters:
        - accelerations: The accelerations to append.
        - to: The measurement to append the accelerations to.
     */
    func append(accelerations: [AccelerationPointMO], to measurement: Int64) throws
    /**
     Creates a data representation from an array of accelerations.

     - Parameter from: An array of `AccelerationPointMO` objects to create a data representation for.
     - Returns: The acceleration points in the Cyface binary format.
     */
    func data(from acceleration: [AccelerationPointMO]) -> Data?
}

extension FileSupport {

    func path(for measurement: Int64) throws -> URL {
        let measurementIdentifier = measurement
        let root = "Application support"
        let measurementDirectory = "measurements"
        let accelerationsFileName = "accel"
        let accelerationsFileExtension = "cyfa"

        let measurementDirectoryPath = try FileManager.default.url(for: FileManager.SearchPathDirectory.libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(root).appendingPathComponent(measurementDirectory).appendingPathComponent(String(measurementIdentifier))
        try FileManager.default.createDirectory(at: measurementDirectoryPath, withIntermediateDirectories: true)

        let filePath = measurementDirectoryPath.appendingPathComponent(accelerationsFileName).appendingPathExtension(accelerationsFileExtension)
        if !FileManager.default.fileExists(atPath: filePath.path) {
            FileManager.default.createFile(atPath: filePath.path, contents: nil)
        }

        return filePath
    }

    func append(accelerations: [AccelerationPointMO], to measurement: Int64) throws {
        let accelerationData = data(from: accelerations)
        let accelerationFilePath = try path(for: measurement)

        if let accelerationData = accelerationData {
            let fileHandle = try FileHandle(forWritingTo: accelerationFilePath)
            defer { fileHandle.closeFile()}
            fileHandle.seekToEndOfFile()
            fileHandle.write(accelerationData)
        }
    }

    func data(from accelerations: [AccelerationPointMO]) -> Data? {
        let serializer = AccelerationSerializer()
        let serializedAcceleration = serializer.serialize(serializable: accelerations)
        return serializedAcceleration
    }
}

/**
 Struct implementing the `FileSupport` protocol.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 2.0.0
 */
struct AccelerationsFile: FileSupport {

}
