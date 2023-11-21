/*
 * Copyright 2022 Cyface GmbH
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
 An upload to a Cyface Data Collector server.

 - author: Klemens Muthmann
 - version: 1.0.0
 */
public protocol Upload {
    /// The amount of failed uploads before retrying is stopped.
    var failedUploadsCounter: Int {get set}

    /// The ``FinishedMeasurement`` to upload.
    var measurement: FinishedMeasurement { get }

    /// Provide the upload meta data of the measurement to upload.
    func metaData() throws -> MetaData

    /// Provide the actual data of the measurement to upload.
    func data() throws -> Data

    /// A function carried out on a successful upload.
    func onSuccess() throws
}

/**
 An upload to a Cyface Data Collector taking data from a CoreData source.

 - author: Klemens Muthmann
 - version 1.0.0
 */
public class CoreDataBackedUpload: Upload {
    /// A wrapper for the `NSPersistentContainer` and the corresponding initialization code.
    var dataStoreStack: DataStoreStack
    /// A cache for the actual measurement to upload, so we don't have to reload it from the database all the time.
    public var measurement: FinishedMeasurement
    /// A cache for the measurements metadata, so we don't have to reload it from the database all the time.
    var dataCache: Data?
    /// A counter of the number of failed attempts to run this upload. This can be used to stop retrying after a certain amount of retries.
    public var failedUploadsCounter = 0
    var identifier: UInt64 {
        measurement.identifier
    }

    /// Make a new instance of this class, connected to a CoreData storage and associated with a measurement, via its `identifier`.
    public init(dataStoreStack: DataStoreStack, measurement: FinishedMeasurement) {
        self.measurement = measurement
        self.dataStoreStack = dataStoreStack
    }

    /// Load the meta data of the measurement from the CoreData storage.
    ///
    /// After the first call this is retrieved from a local cache and not reloaded from storage.
    /// To refresh the values, you need use a new instance of this class.
    public func metaData() throws -> MetaData {
        let bundle = Bundle.main
        guard let appVersion = bundle.infoDictionary?["CFBundleShortVersionString"] as? String else {
            throw ServerConnectionError.dataError("Application version was missing!")
        }

        let length = measurement.trackLength

        let locationCount = measurement.tracks.map { $0.locations.count }.reduce(0) { $0 + $1 }

        let (startLocationLat, startLocationLon, startLocationTs) = try startLocation()

        let (endLocationLat, endLocationLon, endLocationTs) = try endLocation()

        let operatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let range = operatingSystemVersion.range(of: "Version ")!

        return MetaData(
            locationCount: UInt64(locationCount),
            formatVersion: Int(dataFormatVersion),
            startLocLat: startLocationLat,
            startLocLon: startLocationLon,
            startLocTS: startLocationTs,
            endLocLat: endLocationLat,
            endLocLon: endLocationLon,
            endLocTS: endLocationTs,
            measurementId: UInt64(measurement.identifier),
            osVersion: "iOS \(operatingSystemVersion[range.upperBound..<operatingSystemVersion.endIndex])",
            applicationVersion: appVersion,
            length: length,
            modality: try initialModality())
    }

    /// Serialize the data from the measurement to upload into a binary format.
    ///
    /// The measurement is only loaded from the data storage on the first call.
    /// Each subsequent call retrieves the measurement from a local cache.
    /// To refresh the values, you need use a new instance of this class.
    ///
    /// - throws: Either a `SerializationError` if serialization of the measurement failes for some reason or a CoreData error if loading the measurement fails.
    public func data() throws -> Data {
        if let ret = dataCache {
            return ret
        } else {
            let serializer = MeasurementSerializer()

            let ret = try serializer.serializeCompressed(serializable: measurement)
            return ret
        }
    }

    public func onSuccess() throws {
        try dataStoreStack.wrapInContext { context in
            let request = MeasurementMO.fetchRequest()
            request.predicate = NSPredicate(format: "identifier == %d", measurement.identifier)
            let response = try request.execute()
            guard response.count == 1 else {
                throw MeasurementError.inconsistentState
            }

            guard let databaseMeasurement = response.first else {
                throw MeasurementError.notAvailable(measurement: measurement)
            }

            databaseMeasurement.synchronizable = false
            databaseMeasurement.synchronized = true
            try context.save()
        }
    }

    /// Load a measurement from CoreData and return the measurement together with the initial modality.
    private func initialModality() throws -> String {
        guard let initialModality = measurement.events.filter({ if case $0.type = EventType.modalityTypeChange { return true } else { return false }}).min(by: { $0.time < $1.time })?.value else {
            throw ServerConnectionError.modalityError("Invalid modality change event with no value encountered!")
        }

        return initialModality
    }

    /// Provide the start location of the measurement to upload as a triple of latitude, longitude and timestamp or all `nil` if the measurement has no locations.
    func startLocation() throws -> (Double?, Double?, Date?) {
        guard !measurement.tracks.isEmpty else {
            return (nil, nil, nil)
        }
        guard !measurement.tracks[0].locations.isEmpty else {
            return (nil, nil, nil)
        }

        let startLocation = measurement.tracks[0].locations[0]
        return (startLocation.latitude, startLocation.longitude, startLocation.time)
    }

    /// Provide the end location of the measurement to upload as a triple of latitude, longitude and timestamp or all `nil` if the measurement has not locations.
    func endLocation() throws -> (Double?, Double?, Date?) {
        guard !measurement.tracks.isEmpty else {
            return (nil, nil, nil)
        }

        guard let endLocation = measurement.tracks.flatMap({track in track.locations}).last else {
            return (nil, nil, nil)
        }

        return (endLocation.latitude, endLocation.longitude, endLocation.time)
    }
}

/**
 Errors thrown while accessing measurement data to upload.

 - author: Klemens Muthmann
 - version: 1.0.0
 */
enum MeasurementError: Error {
    /// Thrown if the managed object loaded from the database is currently a fault.
    /// This usually means that managed object was accessed at the wrong time or from the wrong thread.
    case faultError
    case notAvailable(measurement: FinishedMeasurement)
    /// Thrown if the database is in an inconsistent state.
    case inconsistentState
}
