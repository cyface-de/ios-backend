/*
 * Copyright 2024 Cyface GmbH
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

/**
 A factory to externalize the creation of ``SensorValueFile`` instances.

 An instance of this class is required to create a ``CapturedDataStorage``.
 Since each measurement requires new instances of a ``SensorValueFile``, this class provides the `CapturedDataStorage` the capability to create the correct type of `SensorValueFile`.
 This can be used if different formats are required or the actual file is mocked for testing.

 - Author: Klemens Muthmann
 */
public protocol SensorValueFileFactory {
    /// The type of object to serialize in the files created from this factory.
    associatedtype Serializable
    /// The serializer for the provided `Serializable`.
    associatedtype SpecificSerializer
    /// The type of objects this factory creates.
    associatedtype FileType: FileSupport where FileType.Serializable == Serializable, FileType.SpecificSerializer == SpecificSerializer
    /// Create the actual file for a certain type
    func create(fileType: SensorValueFileType, qualifier: String) throws -> FileType
}

// MARK: - Implementation
extension SensorValueFileFactory {
    /// The root path used to store data via this app. This is in global scope, so it gets initialized at application start, since finding the location is a computation heavy operation.
    func rootPath() throws -> URL {
        let root = "Application Support"
        let measurementDirectory = "measurements"
        let fileManager = FileManager.default
        let libraryDirectory = FileManager.SearchPathDirectory.libraryDirectory
        let libraryDirectoryUrl = try fileManager.url(for: libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

        let measurementUrl = libraryDirectoryUrl
            .appendingPathComponent(root)
            .appendingPathComponent(measurementDirectory)
        try fileManager.createDirectory(at: measurementUrl, withIntermediateDirectories: true)
        return measurementUrl
    }
}

/**
 Create the default ``SensorValueFile`` required by a recent Cyface Data Collector processing the Protobuf format and using the Google Media Upload Protocol.

 - Author: Klemens Muthmann
 */
public struct DefaultSensorValueFileFactory: SensorValueFileFactory {
    /// This factory is used to create files storing arrays of ``SensorValue``.
    public typealias Serializable = [SensorValue]

    /// This factory creates files that serialize data using a ``SensorValueSerializer``.
    public typealias SpecificSerializer = SensorValueSerializer
    
    /// This factory creates ``SensorValueFile``.
    public typealias FileType = SensorValueFile

    // MARK: - Initializers
    /// Create a new instance of this struct.
    public init() {
        // Nothing to do here.
    }

    /// Create a new ``SensorValueFile``.
    ///
    /// - Parameter qualifier: Used to make the file unique and distinguishable from other files storing the same type of data. Usually this is the measurement identifier.
    /// - Parameter fileType: The type of ``SensorValue`` to store.
    public func create(fileType: SensorValueFileType, qualifier: String) throws -> SensorValueFile {
        return try SensorValueFile(
            rootPath: rootPath(),
            fileType: SensorValueFileType.accelerationValueType,
            qualifier: qualifier
        )
    }
}
