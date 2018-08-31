//
//  FileSupport.swift
//  DataCapturing
//
//  Created by Team Cyface on 29.08.18.
//

import Foundation

protocol FileSupport {
    func path(for measurement: Int64) throws -> URL
    func append(accelerations: [AccelerationPointMO], to measurement: Int64) throws
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

struct AccelerationsFile: FileSupport {

}
