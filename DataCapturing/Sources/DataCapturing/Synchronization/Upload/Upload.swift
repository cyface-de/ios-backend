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
protocol Upload {
    /// The amount of failed uploads before retrying is stopped.
    var failedUploadsCounter: Int {get set}

    /// The device wide unique identifier of the measurement to upload.
    var identifier: UInt64 { get }

    /// Provide the upload meta data of the measurement to upload.
    func metaData() throws -> MetaData

    /// Provide the actual data of the measurement to upload.
    func data() throws -> Data
}

/**
 An upload to a Cyface Data Collector taking data from a CoreData source.

 - author: Klemens Muthmann
 - version 1.0.0
 */
class CoreDataBackedUpload: Upload {
    /// A wrapper for the `NSPersistentContainer` and the corresponding initialization code.
    var dataStoreStack: DataStoreStack
    /// The device wide unique identifier of the measurement to upload.
    var identifier: UInt64
    /// The device wide unique measurement identifier as a signed 64 bit integer.
    var _identifier: Int64 {
        return Int64(identifier)
    }
    /// A cache for the actual measurement to upload, so we don't have to reload it from the database all the time.
    var _measurement: FinishedMeasurement?
    /// A cache for the measurements metadata, so we don't have to reload it from the database all the time.
    var metaDataCache: MetaData?
    /// A cache for the binary data to upload.
    var dataCache: Data?
    /// A counter of the number of failed attempts to run this upload. This can be used to stop retrying after a certain amount of retries.
    var failedUploadsCounter = 0

    /// Provide the measurement to upload from CoreData.
    ///
    /// After the first call this is retrieved from a local cache and not reloaded from the local storage.
    /// To refresh the values, you need use a new instance of this class.
    private func measurement() throws -> FinishedMeasurement {
        let persistenceLayer = dataStoreStack.persistenceLayer()
        if _measurement == nil {
            let loadedMeasurement = try persistenceLayer.load(measurementIdentifiedBy: Int64(identifier))

            _measurement = loadedMeasurement
            return loadedMeasurement
        } else {
            guard let loadedMeasurement = _measurement else {
                throw MeasurementError.faultError
            }

            return loadedMeasurement
        }
    }

    /// Make a new instance of this class, connected to a CoreData storage and associated with a measurement, via its `identifier`.
    init(dataStoreStack: DataStoreStack, identifier: UInt64) {
        self.identifier = identifier
        self.dataStoreStack = dataStoreStack
    }

    /// Load the meta data of the measurement from the CoreData storage.
    ///
    /// After the first call this is retrieved from a local cache and not reloaded from storage.
    /// To refresh the values, you need use a new instance of this class.
    func metaData() throws -> MetaData {
        if let ret = metaDataCache {
            return ret
        } else {
            let persistenceLayer = dataStoreStack.persistenceLayer()
            let (measurement, initialModality) = try measurement(identifier: _identifier)

            let bundle = Bundle.main
            guard let appVersion = bundle.infoDictionary?["CFBundleShortVersionString"] as? String else {
                throw ServerConnectionError.dataError("Application version was missing!")
            }

            let length = measurement.trackLength

            let locationCount = try persistenceLayer.countGeoLocations(forMeasurement: measurement)

            let (startLocationLat, startLocationLon, startLocationTs) = try startLocation()

            let (endLocationLat, endLocationLon, endLocationTs) = try endLocation()

            let ret = MetaData(
                locationCount: UInt64(locationCount),
                formatVersion: Int(dataFormatVersion),
                startLocLat: startLocationLat,
                startLocLon: startLocationLon,
                startLocTS: startLocationTs,
                endLocLat: endLocationLat,
                endLocLon: endLocationLon,
                endLocTS: endLocationTs,
                measurementId: UInt64(measurement.identifier),
                osVersion: "iOS \(ProcessInfo.processInfo.operatingSystemVersionString)",
                applicationVersion: appVersion,
                length: length,
                modality: initialModality)
            metaDataCache = ret
            return ret
        }
    }

    /// Serialize the data from the measurement to upload into a binary format.
    ///
    /// The measurement is only loaded from the data storage on the first call.
    /// Each subsequent call retrieves the measurement from a local cache.
    /// To refresh the values, you need use a new instance of this class.
    ///
    /// - throws: Either a `SerializationError` if serialization of the measurement failes for some reason or a CoreData error if loading the measurement fails.
    func data() throws -> Data {
        if let ret = dataCache {
            return ret
        } else {
            let persistenceLayer = dataStoreStack.persistenceLayer()
            let serializer = MeasurementSerializer()

            let measurement = try persistenceLayer.load(measurementIdentifiedBy: Int64(identifier))
            let ret = try serializer.serializeCompressed(serializable: measurement)
            return ret
        }
    }

    /// Load a measurement from CoreData and return the measurement together with the initial modality.
    private func measurement(identifier: Int64) throws -> (FinishedMeasurement, String) {
        let persistenceLayer = dataStoreStack.persistenceLayer()
        let measurement = try persistenceLayer.load(measurementIdentifiedBy: identifier)

        let modalityTypeChangeEvents = try persistenceLayer.loadEvents(typed: .modalityTypeChange, forMeasurement: measurement)
        guard !modalityTypeChangeEvents.isEmpty else {
            throw ServerConnectionError.modalityError("No modality type information available!")
        }
        guard let initialModality = modalityTypeChangeEvents[0].value else {
            throw ServerConnectionError.modalityError("Invalid modality change event with no value encountered!")
        }

        return (measurement, initialModality)
    }

    /// Provide the start location of the measurement to upload as a triple of latitude, longitude and timestamp or all `nil` if the measurement has no locations.
    func startLocation() throws -> (Double?, Double?, Date?) {
        let persistenceLayer = dataStoreStack.persistenceLayer()
        let measurement = try persistenceLayer.load(measurementIdentifiedBy: Int64(identifier))

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
        let persistenceLayer = dataStoreStack.persistenceLayer()
        let measurement = try persistenceLayer.load(measurementIdentifiedBy: Int64(identifier))

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
}
