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

/**
 A factory to externalize the creation of ``SensorValueFile`` instances.

 An instance of this class is required to create a ``CapturedDataStorage``.
 Since each measurement requires new instances of a ``SensorValueFile``, this class provides the `CapturedDataStorage` the capability to create the correct type of `SensorValueFile`.
 This can be used if different formats are required or the actual file is mocked for testing.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
public protocol SensorValueFileFactory {
    /// Create the actual file for a certain type
    func create(fileType: SensorValueFileType, qualifier: String) -> SensorValueFile
}

/**
 Create the default ``SensorValueFile`` required by a recent Cyface Data Collector processing the Protobuf format and using the Google Media Upload Protocol.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
public struct DefaultSensorValueFileFactory: SensorValueFileFactory {
    public func create(fileType: SensorValueFileType, qualifier: String) -> SensorValueFile {
        return SensorValueFile(
            fileType: SensorValueFileType.accelerationValueType,
            qualifier: String(measurementMo.unsignedIdentifier)
        )
    }
}
