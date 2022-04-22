//
//  FakeMeasurement.swift
//  DataCapturingTests
//
//  Created by Team Cyface on 17.02.20.
//  Copyright © 2020 Cyface GmbH. All rights reserved.
//

import Foundation
@testable import DataCapturing

/**
 A builder for fake measurements. It provides a fluent API and should be created via the static factory method `fakeMeasurement`.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
public class FakeMeasurementImpl: FakeMeasurement, FakeTrack {
    /// The fake measurement currently built.
    private var fakeMeasurement: DataCapturing.Measurement
    /// The `PersistenceLayer` used to create the fake measurement.
    private let persistenceLayer: PersistenceLayer

    /**
     Creates a new completely initialized object of this class. The constructor is private to make sure objects are only initialized via the static factory method.

     - Parameters:
        - persistenceLayer: The `PersistenceLayer` used to create the fake measurement
        - measurement: The initial value for the faked measurement
     */
    private init(persistenceLayer: PersistenceLayer, measurement: DataCapturing.Measurement) {
        self.persistenceLayer = persistenceLayer
        self.fakeMeasurement = measurement
    }

    public func build() throws -> DataCapturing.Measurement {
        return try persistenceLayer.save(measurement: fakeMeasurement)
    }

    public func addGeoLocationsAnd(countOfGeoLocations: Int) throws -> FakeTrack {
        try geoLocations(countOfGeoLocations: countOfGeoLocations)

        return self
    }

    public func addAccelerationsAnd(countOfAccelerations: Int) throws -> FakeTrack {
        try accelerations(countOfAccelerations: countOfAccelerations)

        return self
    }

    public func addGeoLocations(countOfGeoLocations: Int) throws -> FakeMeasurement {
        try geoLocations(countOfGeoLocations: countOfGeoLocations)

        return self
    }

    public func addAccelerations(countOfAccelerations: Int) throws -> FakeMeasurement {
        try accelerations(countOfAccelerations: countOfAccelerations)

        return self
    }

    /**
     Internal method actually creating the fake test locations.

     - Parameter countOfGeoLocations: The amount of geo locations to create within the test measurement
     - Throws:
        - Some unspecified errors from within CoreData.
     */
    private func geoLocations(countOfGeoLocations: Int) throws {
        var locations = [LocationCacheEntry]()

        let startTime = Date()
        for i in 0..<countOfGeoLocations {
            let location = LocationCacheEntry(latitude: Double.random(in: -90.0...90.0), longitude: Double.random(in: -180.0...180.0), accuracy: Double.random(in: 0.0...20.0), speed: Double.random(in: 0.0...80.0), timestamp: startTime.addingTimeInterval(Double(i)), isValid: true)

            locations.append(location)
        }
        try persistenceLayer.save(locations: locations, in: &fakeMeasurement)
    }

    /**
     Internal method actually creating the fake test accelerations.

     - Parameter countOfAccelerations: The amount of accelerations to create within the test measurement
     - Throws:
        - Some unspecified errors from within CoreData.
        - Some internal file system error on failure of accessing the acceleration file at the required path.
     */
    private func accelerations(countOfAccelerations: Int) throws {
        fakeMeasurement.accelerationsCount = Int32(countOfAccelerations)
        var accelerations = [SensorValue]()

        for _ in 0..<countOfAccelerations {
            let acceleration = SensorValue(timestamp: Date(), x: Double.random(in: -10.0...10.0), y: Double.random(in: -10.0...10.0), z: Double.random(in: -10.0...10.0))
            accelerations.append(acceleration)
        }
        try persistenceLayer.save(accelerations: accelerations, in: &fakeMeasurement)
    }

    /**
     Create a measurement on the test persistence layer for serialization.

     - Parameter persistenceLayer: The `PersistenceLayer` used to create the fake measurement
     - Returns: The created test measurement builder
     - Throws:
        - Some unspecified errors from within CoreData.
     */
    public static func fakeMeasurement(persistenceLayer: PersistenceLayer) throws -> FakeMeasurement {

        var measurement = try persistenceLayer.createMeasurement(at: DataCapturingService.currentTimeInMillisSince1970(), inMode: "BICYCLE")
        measurement.synchronized = false
        measurement.trackLength = Double.random(in: 0..<10_000.0)

        let ret = FakeMeasurementImpl(persistenceLayer: persistenceLayer, measurement: measurement)
        return ret
    }

    public func appendTrack() throws -> FakeMeasurement {
        try persistenceLayer.appendNewTrack(to: &fakeMeasurement)
        return self
    }

    public func appendTrackAnd() throws -> FakeTrack {
        try persistenceLayer.appendNewTrack(to: &fakeMeasurement)
        return self
    }
}

/**
 Builder state when working on a complete measurement. This provides all methods allowed while building the measurement as a whole.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
public protocol FakeMeasurement {
    /**
     Appends a new track to the measurement and allows to manipulate that track, like adding data.

     - Returns: The builder for the appended track
     */
    func appendTrackAnd() throws -> FakeTrack
    /**
     Appends a new empty track to the measurement.

     - Returns: The current measurement builder
     */
    func appendTrack() throws -> FakeMeasurement
    /**
     Create the product of this builder.

     - Returns: A completely intialized fake measurement
     */
    func build() throws -> DataCapturing.Measurement
}

/**
 Builder state when adding data to a track. This provides all methods allowed while building a track.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
public protocol FakeTrack {
    /**
     Adds the specified amount of geo locations to a track and allows to manipulate that track even further.

     - Parameter countOfGeoLocations: The amount of geo locations to create within the test measurement
     - Returns: The current fake track builder
     */
    func addGeoLocationsAnd(countOfGeoLocations: Int) throws -> FakeTrack
    /**
    Adds the specified amount of accelerations to a track and allows to manipulate that track even further.

     - Parameter countOfAccelerations: The amount of accelerations to create within the test measurement
     - Returns: The current fake track builder
     */
    func addAccelerationsAnd(countOfAccelerations: Int) throws -> FakeTrack
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
}
