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
import Foundation
import Combine
import OSLog
import CoreData

/**
 Protocol for a storage process for captured sensor data.

 Implementations of this protocol are capable of storing captured data to some kind of permanent storage.

 - author: Klemens Muthmann
 - version: 1.0.0
 */
public protocol CapturedDataStorage {
    /// Create a new measurement within the data store.
    func createMeasurement(_ initialMode: String) throws -> UInt64
    /// Subscribe to a running measurement and store the data produced by that measurement.
    func subscribe(
        to measurement: Measurement,
        _ identifier: UInt64,
        _ receiveCompletion: @escaping (() -> Void)) throws
    /// Stop receiving updates from the currently subscribed measurement or do nothing if this was not subscribed at the moment.
    func unsubscribe()
}

/**
An implementation of `CapturedDataStorage` for storing the data to a CoreData database.

 - author: Klemens Muthmann
 - version: 1.0.1
 */
public class CapturedCoreDataStorage {
    /// The `DataStoreStack` to write the captured data to.
    let dataStoreStack: DataStoreStack
    /// A queue used to buffer received data until writing it as a bulk for performance reasons.
    let cachingQueue = DispatchQueue(label: "de.cyface.cache")
    /// The time interval to wait until the next batch of data is stored to the data storage. Increasing this time should improve performance but increases memory usage.
    let interval: TimeInterval
    /// The *Combine* cancellables used so new values are transmitted.
    var cancellables = [AnyCancellable]()

    /**
     - Parameter interval: The time interval to wait until the next batch of data is stored to the data storage. Increasing this time should improve performance but increases memory usage.
     */
    public init(_ dataStoreStack: DataStoreStack, _ interval: TimeInterval) {
        self.dataStoreStack = dataStoreStack
        self.interval = interval
    }


}

extension CapturedCoreDataStorage: CapturedDataStorage {

    public func createMeasurement(_ initialMode: String) throws -> UInt64 {
        return try dataStoreStack.wrapInContextReturn { context in
            let time = Date()
            let measurementMO = MeasurementMO(context: context)
            measurementMO.time = time
            let identifier = try dataStoreStack.nextValidIdentifier()
            measurementMO.identifier = Int64(identifier)
            measurementMO.synchronized = false
            measurementMO.synchronizable = false
            measurementMO.addToEvents(EventMO(event: Event(time: time, type: .modalityTypeChange, value: initialMode), context: context))
            try context.save()
            return identifier
        }
    }

    /// Recievie updates from the provided ``Measurement`` and store the data to a ``DataStoreStack``.
    public func subscribe(
        to measurement: Measurement,
        _ identifier: UInt64,
        _ receiveCompletion: @escaping (() -> Void)
    ) throws {
        let cachedFlow = measurement.measurementMessages.collect(.byTime(cachingQueue, 1.0))
        cachedFlow
            .sink(receiveCompletion: { _ in
                os_log(
                    "Completing storage flow.",
                    log: OSLog.persistence,
                    type: .debug
                )
                receiveCompletion()
            }) { [weak self] (messages: [Message]) in
                do {
                    try self?.dataStoreStack.wrapInContext { context in
                        guard let measurementRequest = context.persistentStoreCoordinator?.managedObjectModel.fetchRequestFromTemplate(withName: "measurementByIdentifier", substitutionVariables: ["identifier": identifier]) else {
                            os_log(
                                "Unable to load measurement fetch request.",
                                log: OSLog.persistence,
                                type: .debug
                            )
                            return
                        }
                        guard let measurement = try measurementRequest.execute().first as? MeasurementMO else {
                            os_log(
                                "Unable to load measurement to store to",
                                log: OSLog.persistence,
                                type: .debug
                            )
                            return
                        }

                        let accelerationsFile = SensorValueFile(
                            fileType: SensorValueFileType.accelerationValueType,
                            qualifier: String(measurement.unsignedIdentifier)
                        )
                        let rotationsFile = SensorValueFile(
                            fileType: SensorValueFileType.rotationValueType,
                            qualifier: String(measurement.unsignedIdentifier)
                        )
                        let directionsFile = SensorValueFile(
                            fileType: SensorValueFileType.directionValueType,
                            qualifier: String(measurement.unsignedIdentifier)
                        )

                        try messages.forEach { message in
                            switch message {
                            case .capturedLocation(let location):
                                os_log(
                                    "Storing location to database.",
                                    log: OSLog.persistence,
                                    type: .debug
                                )
                                if let lastTrack = measurement.typedTracks().last {
                                    lastTrack.addToLocations(GeoLocationMO(location: location, context: context))
                                }
                            case .capturedAltitude(let altitude):
                                if let lastTrack = measurement.typedTracks().last {
                                    lastTrack.addToAltitudes(AltitudeMO(altitude: altitude, context: context))
                                }
                            case .capturedRotation(let rotation):
                                do {
                                    _ = try rotationsFile.write(serializable: [rotation])
                                } catch {
                                    debugPrint("Unable to write data to file \(rotationsFile.fileName)!")
                                    throw error
                                }
                            case .capturedDirection(let direction):
                                do {
                                    _ = try directionsFile.write(serializable: [direction])
                                } catch {
                                    debugPrint("Unable to write data to file \(directionsFile.fileName)!")
                                    throw error
                                }
                            case .capturedAcceleration(let acceleration):
                                do {
                                    _ = try accelerationsFile.write(serializable: [acceleration])
                                } catch {
                                    debugPrint("Unable to write data to file \(accelerationsFile.fileName)!")
                                    throw error
                                }
                            case .started(timestamp: let time):
                                os_log("Storing started event to database.", log: OSLog.persistence, type: .debug)
                                measurement.addToTracks(TrackMO(context: context))
                                measurement.addToEvents(EventMO(event: Event(time: time, type: .lifecycleStart), context: context))
                            case .resumed(timestamp: let time):
                                measurement.addToTracks(TrackMO(context: context))
                                measurement.addToEvents(EventMO(event: Event(time: time, type: .lifecycleResume), context: context))
                            case .paused(timestamp: let time):
                                measurement.addToEvents(EventMO(event: Event(time: time, type: .lifecyclePause), context: context))
                            case .stopped(timestamp: let time):
                                os_log("Storing stopped event to database.", log: OSLog.persistence, type: .debug)
                                measurement.addToEvents(EventMO(event: Event(time: time, type: .lifecycleStop), context: context))
                                measurement.synchronizable = true
                            default:
                                os_log("Message %{PUBLIC}@ irrelevant for data storage and thus ignored.",log: OSLog.persistence, type: .debug, message.description)
                            }
                        }

                        try context.save()
                    }
                } catch {
                    os_log("Unable to store data! Error %{PUBLIC}@",log: OSLog.persistence ,type: .error, error.localizedDescription)
                }
            }.store(in: &cancellables)
    }

    public func unsubscribe() {
        cancellables.forEach { cancellable in
            cancellable.cancel()
        }
        cancellables.removeAll(keepingCapacity: true)
    }
}
