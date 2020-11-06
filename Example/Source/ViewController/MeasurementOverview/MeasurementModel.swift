//
// Copyright (C) 2018 - 2020 Cyface GmbH - All Rights Reserved
// Unauthorized copying of this file, via any medium is strictly prohibited
// Proprietary and confidential
//

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
    private var _measurement: MeasurementMO?
    /// The database entity representing the current measurement
    var measurement: MeasurementMO? {
        get {
            if _measurement==nil {
                return nil
            } else {
                guard let _measurement = _measurement else {
                    fatalError("Unable to access current measurement!")
                }

                if _measurement.isFault {
                    let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
                    persistenceLayer.makeContext().refresh(_measurement, mergeChanges: true)
                }

                return _measurement
            }
        }
        set {
            _measurement = newValue
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
    var timestamp: Int64? {
        return mostRecentGeoLocation?.timestamp
    }
    /// The longitude of the most recent captured geo location
    var lastLon: Double? {
        return mostRecentGeoLocation?.lon
    }
    /// The latitude of the most recent captured geo location
    var lastLat: Double? {
        return mostRecentGeoLocation?.lat
    }
    /// The current modality context of the active measurement
    var context: Modality? {
        if modalities.count > 0 {
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
    var initialTimestamp: Int64? {
        return measurement?.timestamp
    }
    /// The most recent geo location captured by the active measurement
    var mostRecentGeoLocation: GeoLocationMO? {
        get {
            guard let mostRecentTrack = measurement?.tracks?.array.last as? Track else {
                fatalError()
            }

            guard let mostRecentGeoLocation = mostRecentTrack.locations?.array.last as? GeoLocationMO else {
                return nil
            }

            return mostRecentGeoLocation
        }
    }
    /// The transporation modes used to capture this measurement in chronological order.
    var modalities: [Modality] {
        get {
            do {
                let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
                persistenceLayer.context = persistenceLayer.makeContext()
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
    public convenience init(_ coreDataStack: CoreDataManager, measurement: MeasurementMO) {
        self.init(coreDataStack)
        self.measurement = measurement
    }

    /**
     Deletes the measurement from the application

     - Parameter onDeleted: A closure called when deletion has finished
     */
    func delete(onDeleted: ()->Void) {
        guard let identifier = identifier else {
            fatalError("Unable to delete measurement. No measurement loaded!")
        }

        let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
        persistenceLayer.context = persistenceLayer.makeContext()

        do {
            try persistenceLayer.delete(measurement: identifier)
        } catch {
            fatalError("Unable to delete measurement. \(error.localizedDescription)")
        }
        onDeleted()
    }

}
