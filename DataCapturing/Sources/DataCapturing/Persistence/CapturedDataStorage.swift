//
//  File.swift
//  
//
//  Created by Klemens Muthmann on 24.05.23.
//

import Foundation
import Combine
import OSLog
import CoreData

public protocol CapturedDataStorage {
    func subscribe(to measurement: Measurement,_ initialMode: String, _ receiveCompletion: @escaping (() -> Void)) throws -> UInt64
}

/**
 - author: Klemens Muthmann
 - version: 1.0.0
 */
public class CapturedCoreDataStorage {
    let dataStoreStack: DataStoreStack
    let cachingQueue = DispatchQueue(label: "de.cyface.cache")
    /// The time interval to wait until the next batch of data is stored to the data storage. Increasing this time should improve performance but increases memory usage.
    let interval: TimeInterval
    var cancellables = [AnyCancellable]()

    /**
     - Parameter interval: The time interval to wait until the next batch of data is stored to the data storage. Increasing this time should improve performance but increases memory usage.
     */
    public init(_ dataStoreStack: DataStoreStack, _ interval: TimeInterval) {
        self.dataStoreStack = dataStoreStack
        self.interval = interval
    }

    private func createMeasurement(_ initialMode: String) throws -> UInt64 {
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
}

extension CapturedCoreDataStorage: CapturedDataStorage {
    /// Recievie updates from the provided ``Measurement`` and store the data to a ``DataStoreStack``.
    public func subscribe(to measurement: Measurement, _ initialMode: String, _ receiveCompletion: @escaping (() -> Void)) throws -> UInt64 {
        let ret = try createMeasurement(initialMode)
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
                        guard let measurementRequest = context.persistentStoreCoordinator?.managedObjectModel.fetchRequestFromTemplate(withName: "measurementByIdentifier", substitutionVariables: ["identifier": ret]) else {
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

                        messages.forEach { message in
                            switch message {
                            case .capturedLocation(let location):
                                os_log("Storing location to database.", log: OSLog.persistence, type: .debug)
                                if let lastTrack = measurement.typedTracks().last {
                                    lastTrack.addToLocations(GeoLocationMO(location: location, context: context))
                                }
                            case .capturedAltitude(let altitude):
                                if let lastTrack = measurement.typedTracks().last {
                                    lastTrack.addToAltitudes(AltitudeMO(altitude: altitude, context: context))
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
                    os_log("Unable to store location! Error %{PUBLIC}@",log: OSLog.persistence ,type: .error, error.localizedDescription)
                }
            }.store(in: &cancellables)
        return ret
    }
}
