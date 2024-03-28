/*
 * Copyright 2023-2024 Cyface GmbH
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

import Combine

/**
 Implementations of this `protocol` provide a process to upload ``FinishedMeasurement`` instances to a server.

 Instances of this class can be used by applications using the Cyface SDK to synchronize with an external server such as the Cyface Server.
 Default implementations are provided to upload data directly via the ``DefaultUploadProcess`` or run uploads in the background at a convenient time via the ``BackgroundUploadProcess``.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
public protocol UploadProcess {
    /// Reports a constant stream of ``UploadStatus`` information about the currently ongoing uploads.
    var uploadStatus: PassthroughSubject<UploadStatus, Never> { get }
    /// Start the upload process for the provided ``FinishedMeasurement``.
    /// Called after authentication with the Cyface data collector service was successful.
    /// - returns: The successful upload
    mutating func upload(measurement: FinishedMeasurement) async throws -> any Upload
}

