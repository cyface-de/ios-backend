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
    var coreDataStack: CoreDataManager
    var identifier: UInt64
    var _identifier: Int64 {
        return Int64(identifier)
    }
    var _measurement: MeasurementMO?
    var metaDataCache: MetaData?
    var dataCache: Data?
    var failedUploadsCounter = 0

    private func measurement() throws -> MeasurementMO {
        let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
        let context = persistenceLayer.makeContext()
        if _measurement == nil {
            let loadedMeasurement = try persistenceLayer.load(measurementIdentifiedBy: Int64(identifier))

            _measurement = loadedMeasurement
            return loadedMeasurement
        } else if let loadedMeasurement = _measurement, loadedMeasurement.isFault {
            context.refresh(loadedMeasurement, mergeChanges: true)
            _measurement = loadedMeasurement

            return loadedMeasurement
        } else {
            guard let loadedMeasurement = _measurement else {
                throw MeasurementError.faultError
            }

            return loadedMeasurement
        }
    }

    init(coreDataStack: CoreDataManager, identifier: UInt64) {
        self.identifier = identifier
        self.coreDataStack = coreDataStack
    }

    func metaData() throws -> MetaData {
        if let ret = metaDataCache {
            return ret
        } else {
            let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
            _ = persistenceLayer.makeContext()
            let (measurement, initialModality) = try measurement(identifier: _identifier)

            let bundle = Bundle(for: type(of: self))
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
                osVersion: "iOS \(UIDevice.current.systemVersion)",
                applicationVersion: appVersion,
                length: length,
                modality: initialModality)
            metaDataCache = ret
            return ret
        }
    }

    /// - throws: Either a `SerializationError` of serialization of the measurement failes for some reason or a CoreData error if loading the measurement fails.
    func data() throws -> Data {
        if let ret = dataCache {
            return ret
        } else {
            let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
            persistenceLayer.context = persistenceLayer.makeContext()
            let serializer = MeasurementSerializer()

            let measurement = try persistenceLayer.load(measurementIdentifiedBy: Int64(identifier))
            let ret = try serializer.serializeCompressed(serializable: measurement)
            return ret
        }
    }

    private func measurement(identifier: Int64) throws -> (MeasurementMO, String) {
        let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
        _ = persistenceLayer.makeContext()
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

    func startLocation() throws -> (Double?, Double?, UInt64?) {
        let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
        _ = persistenceLayer.makeContext()
        let measurement = try persistenceLayer.load(measurementIdentifiedBy: Int64(identifier))

        guard let firstTrack = measurement.tracks?[0] as? Track else {
            return (nil, nil, nil)
        }
        guard let startLocation = firstTrack.locations?.firstObject as? GeoLocationMO else {
            return (nil, nil, nil)
        }

        return (startLocation.lat, startLocation.lon, UInt64(startLocation.timestamp))
    }

    func endLocation() throws -> (Double?, Double?, UInt64?) {
        let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
        _ = persistenceLayer.makeContext()
        let measurement = try persistenceLayer.load(measurementIdentifiedBy: Int64(identifier))

        guard let lastTrack = measurement.tracks?.lastObject as? Track else {
            return (nil, nil, nil)
        }

        guard let endLocation = lastTrack.locations?.lastObject as? GeoLocationMO else {
            return (nil, nil, nil)
        }

        return (endLocation.lat, endLocation.lon, UInt64(endLocation.timestamp))
    }
}

enum MeasurementError: Error {
    case faultError
}
