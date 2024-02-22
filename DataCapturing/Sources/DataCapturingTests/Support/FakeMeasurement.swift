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
@testable import DataCapturing

/**
 A builder for fake measurements. It provides a fluent API and should be created via the static factory method `fakeMeasurement`.

 - Author: Klemens Muthmann
 - Version: 2.0.0
 - since: 10.0.0
 */
public class FakeMeasurementImpl: FakeMeasurement {
    /// The array of accelerations used for the currently built `Measurement`.
    private var accelerations = [SensorValue]()
    private var tracks = [[GeoLocation]]()
    private var identifier: UInt64
    private var currentTime = Date()
    private let startingTime = Date()

    init(identifier: UInt64) {
        self.identifier = identifier
    }

    public func build(_ persistenceLayer: PersistenceLayer) throws -> FinishedMeasurement {
        let measurement = FinishedMeasurement(
            identifier: identifier,
            synchronizable: false,
            synchronized: false,
            time: Date(),
            events: [], tracks: [])
        /*measurement.append(
            event: Event(
                time: startingTime,
                type: .modalityTypeChange,
                value: "BICYCLE"
            )
        )*/

        /*tracks.forEach { locations in
            let track = Track()
            track.locations = locations
            measurement.append(track: track)
        }*/
        var synchronizedMeasurement = try persistenceLayer.save(measurement: measurement)
        try persistenceLayer.save(accelerations: accelerations, in: &synchronizedMeasurement)
        return synchronizedMeasurement

    }

    public func addGeoLocations(countOfGeoLocations: Int) throws -> FakeMeasurement {
        tracks.append(geoLocations(countOfGeoLocations: countOfGeoLocations))

        return self
    }

    public func addAccelerations(countOfAccelerations: Int) throws -> FakeMeasurement {
        try accelerations(countOfAccelerations: countOfAccelerations)

        return self
    }

    /**
     Internal method actually creating the fake test locations.

     - Parameter countOfGeoLocations: The amount of geo locations to create within the test measurement
     - Throws: `FakeMeasurementError.noTrackCreated` if trying to add a geo location without a proper track available. In such cases call `appendTrack` or `appendTrackAnd` before calling this method.
     */
    private func geoLocations(countOfGeoLocations: Int) -> [GeoLocation] {
        let ret = (0..<countOfGeoLocations).map { index in
            GeoLocation(
                latitude: Double.random(in: -90.0...90.0),
                longitude: Double.random(in: -180.0...180.0),
                accuracy: Double.random(in: 0.0...20.0),
                speed: Double.random(in: 0.0...80.0),
                time: currentTime.addingTimeInterval(Double(index)),
                altitude: 0.0,
                verticalAccuracy: 0.0
            )
        }
        currentTime = currentTime.addingTimeInterval(Double(countOfGeoLocations))
        return ret
    }

    /**
     Internal method actually creating the fake test accelerations.

     - Parameter countOfAccelerations: The amount of accelerations to create within the test measurement
     - Throws:
        - Some unspecified errors from within CoreData.
        - Some internal file system error on failure of accessing the acceleration file at the required path.
     */
    private func accelerations(countOfAccelerations: Int) throws {
        for _ in 0..<countOfAccelerations {
            accelerations.append(
                SensorValue(
                timestamp: Date(),
                x: Double.random(in: -10.0...10.0),
                y: Double.random(in: -10.0...10.0),
                z: Double.random(in: -10.0...10.0)
                )
            )
        }
    }

    /**
     Create a measurement on the test persistence layer for serialization.

     - Parameter persistenceLayer: The `PersistenceLayer` used to create the fake measurement
     - Returns: The created test measurement builder
     - Throws:
        - Some unspecified errors from within CoreData.
     */
    public static func fakeMeasurement(identifier: UInt64) throws -> FakeMeasurement {
        let ret = FakeMeasurementImpl(identifier: identifier)
        return ret
    }
}

/**
 Builder state when working on a complete measurement. This provides all methods allowed while building the measurement as a whole.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
public protocol FakeMeasurement {
    /**
     Add the specified amount of geo locations to a track and finishes manipulation of that track.

     - Parameter countOfGeoLocations: The amount of geo locations to create within the test measurement
     - Returns: The current fake measurement builder
     */
    func addGeoLocations(countOfGeoLocations: Int) throws -> FakeMeasurement
    /**
     Add the specified amount of accelerations to a track and finishes manipulation of that track.

     - Parameter countOfAccelerations: The amount of accelerations to create within the test measurement
     - Returns: The current fake measurement builder
     */
    func addAccelerations(countOfAccelerations: Int) throws -> FakeMeasurement
    /**
     Create the product of this builder.
     Finishes the creation of the fake measurement by storing it to the database.

     - Parameter persistenceLayer: A `PersistenceLayer` used to store the created measurement
     - Returns: A completely intialized fake measurement
     */
    func build(_ persistenceLayer: PersistenceLayer) throws -> FinishedMeasurement
}

/**
 Errors thrown while creating a faked `Measurement`.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
enum FakeMeasurementError: Error {
    /// If someone tried to add a location before adding a track.
    case noTrackCreated
}
