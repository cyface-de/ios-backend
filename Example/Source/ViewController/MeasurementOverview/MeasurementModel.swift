/*
* Copyright 2018 - 2022 Cyface GmbH
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
import DataCapturing

/**
 A representation of a measurement with access to the underlying database.

 - Author: Klemens Muthmann
 - Version: 1.1.0
 - Since: 2.0.0
 */
class MeasurementModel {
    /// Internal storage for the current measurement database entity
    private var internalMeasurement: DataCapturing.Measurement?
    /// The database entity representing the current measurement
    var measurement: DataCapturing.Measurement? {
        get {
            if internalMeasurement==nil {
                return nil
            } else {
                guard let internalMeasurement = internalMeasurement else {
                    fatalError("Unable to access current measurement!")
                }

                let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
                do {
                    self.internalMeasurement = try persistenceLayer.load(measurementIdentifiedBy: internalMeasurement.identifier)
                    return internalMeasurement
                } catch {
                    fatalError("Unable to load measurement")
                }
            }
        }
        set {
            internalMeasurement = newValue
        }
    }
    /// A value that is `true` if the current measurement has a geo location fix and `false` otherwise
    var hasFix = false
    /// The current distance covered by the active measurement
    var distance: Double? {
        return measurement?.trackLength
    }
    /// The current speed of the active measurement
    var speed: Double? {
        return mostRecentGeoLocation?.speed
    }
    /// The timestamp of the most recent captured geo location
    var timestamp: UInt64? {
        return mostRecentGeoLocation?.timestamp
    }
    /// The longitude of the most recent captured geo location
    var lastLon: Double? {
        return mostRecentGeoLocation?.longitude
    }
    /// The latitude of the most recent captured geo location
    var lastLat: Double? {
        return mostRecentGeoLocation?.latitude
    }
    /// The current modality context of the active measurement
    var context: Modality? {
        if !modalities.isEmpty {
            return modalities[0]
        } else {
            return nil
        }
    }
    /// The device wide unique identifier of the active measurement
    var identifier: Int64? {
        return measurement?.identifier
    }
    /// The timestamp of the start of the active measurement
    var initialTimestamp: UInt64? {
        return measurement?.timestamp
    }
    /// The most recent geo location captured by the active measurement
    var mostRecentGeoLocation: GeoLocation? {
        guard let mostRecentTrack = measurement?.tracks.last else {
            fatalError()
        }

        guard let mostRecentGeoLocation = mostRecentTrack.locations.last else {
            return nil
        }

        return mostRecentGeoLocation
    }
    /// The transporation modes used to capture this measurement in chronological order.
    var modalities: [Modality] {
        do {
            let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
            let events = try persistenceLayer.loadEvents(typed: .modalityTypeChange, forMeasurement: measurement!)
            let modalities: [Modality] = events.map { event in
                guard let rawValue = event.value else {
                    fatalError("No modality provided for modality change event!")
                }

                let modality = Modality.from(dbValue: rawValue)

                return modality
            }
            return modalities
        } catch {
            fatalError("Unable to access database!")
        }
    }
    /// The stack used to access the `CoreData` stack to load the measurement data
    private let coreDataStack: CoreDataManager
    /**
     Creates a new representation of a current measurement

     - Parameter coreDataStack: The stack used to access the `CoreData` stack to load the measurement data
     */
    public init(_ coreDataStack: CoreDataManager) {
        self.coreDataStack = coreDataStack
    }
    /**
        Creates a new representation of a current measurement

     - Parameters:
        - coreDataStack: The stack used to access the `CoreData` stack to load the measurement data
        - measurement: The database object this model is based on
     */
    public convenience init(_ coreDataStack: CoreDataManager, measurement: DataCapturing.Measurement) {
        self.init(coreDataStack)
        self.measurement = measurement
    }

    /**
     Deletes the measurement from the application

     - Parameter onDeleted: A closure called when deletion has finished
     */
    func delete(onDeleted: () -> Void) {
        guard let identifier = identifier else {
            fatalError("Unable to delete measurement. No measurement loaded!")
        }

        let persistenceLayer = PersistenceLayer(onManager: coreDataStack)

        do {
            try persistenceLayer.delete(measurement: identifier)
        } catch {
            fatalError("Unable to delete measurement. \(error.localizedDescription)")
        }
        onDeleted()
    }

}
