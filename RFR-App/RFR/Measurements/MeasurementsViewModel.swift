//
//  MeasurementsViewModel.swift
//  RFR
//
//  Created by Klemens Muthmann on 11.04.23.
//

import Foundation
import DataCapturing
import Combine
import CoreLocation
import MapKit

class MeasurementsViewModel: ObservableObject {
    /// The measurements displayed by this view.
    @Published var measurements: [Measurement]
    @Published var isLoading = true
    @Published var error: Error? = nil
    let syncQueue = DispatchQueue(label: "measurements-view-operations")
    var uploadSubscription: AnyCancellable?
    let dataStoreStack: DataStoreStack

    // TODO: Why is it not possible to call this async? It is going to take some time for larger amounts of measurements.
    init(dataStoreStack: DataStoreStack, uploadPublisher: some Publisher<UploadStatus, Never>) {
        self.measurements = [Measurement]()
        self.dataStoreStack = dataStoreStack
        uploadSubscription = uploadPublisher
            .receive(on: syncQueue).map {
                return self.update(measurement: $0.id, syncState: $0.status)
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.measurements, on: self)

        do {
            try dataStoreStack.wrapInContext { context in
                let request = MeasurementMO.fetchRequest()
                try request.execute().forEach { measurement in
                    measurements.append(load(measurement: measurement))
                }
                isLoading = false
            }
        } catch {
            self.error = error
        }
    }

    private func load(measurement: MeasurementMO) -> Measurement {
        var maxSpeed = 0.0
        var sumSpeed = 0.0
        var locationCount = 0
        var summedDuration = TimeInterval()
        var lowestPoint = 0.0
        var highestPoint = 0.0
        var heightProfile = [Altitude]()
        let tracks = measurement.typedTracks()
        var coordinates = [CLLocationCoordinate2D]()
        var minimumLatitude = 90.0
        var minimumLongitude = 180.0
        var maximumLatitude = -90.0
        var maximumLongitude = -180.0
        for track in tracks {
            let locations = track.typedLocations()
            guard let firstLocationTime = locations.first?.time else {
                continue
            }
            guard let lastLocationTime = locations.last?.time else {
                continue
            }
            summedDuration += lastLocationTime.timeIntervalSince(firstLocationTime)

            locations.forEach { location in
                maxSpeed = max(maxSpeed, location.speed)
                sumSpeed += location.speed
                locationCount += 1

                coordinates.append(CLLocationCoordinate2D(latitude: location.lat, longitude: location.lon))

                minimumLatitude = min(minimumLatitude, location.lat)
                minimumLongitude = min(minimumLongitude, location.lon)
                maximumLatitude = max(maximumLatitude, location.lat)
                maximumLongitude = max(maximumLongitude, location.lon)
            }

            track.typedAltitudes().enumerated().forEach { (index, altitude) in
                heightProfile.append(Altitude(id: Int64(index), timestamp: altitude.time!, height: altitude.altitude))
                lowestPoint = min(lowestPoint, altitude.altitude)
                highestPoint = max(highestPoint, altitude.altitude)
            }
        }
        let inclination = summedHeight(timelines: measurement.typedTracks())
        let distance = coveredDistance(tracks: tracks)

        let latitudeDistance = maximumLatitude - minimumLatitude
        let longitudeDistance = maximumLongitude - minimumLongitude

        let southWestCorner = CLLocation(latitude: minimumLatitude, longitude: minimumLongitude)
        let northWestCorner = CLLocation(latitude: maximumLatitude, longitude: minimumLongitude)
        //let southEastCorner = CLLocation(latitude: minimumLatitude, longitude: maximumLongitude)
        let northEastCorner = CLLocation(latitude: maximumLatitude, longitude: maximumLongitude)
        let center = CLLocationCoordinate2D(
            latitude: northWestCorner.coordinate.latitude - latitudeDistance/2,
            longitude: northWestCorner.coordinate.longitude + longitudeDistance/2
        )
        let northSouthReach = southWestCorner.distance(from: northWestCorner)
        let eastWestReach = northWestCorner.distance(from: northEastCorner)
        return Measurement(
            id: UInt64(measurement.identifier),
            startTime: measurement.time ?? Date(),
            synchronizationState: SynchronizationState.from(measurement: measurement),
            _maxSpeed: maxSpeed,
            _meanSpeed: sumSpeed / Double(locationCount),
            _distance: distance,
            _duration: summedDuration,
            _inclination: inclination,
            _lowestPoint: lowestPoint,
            _highestPoint: highestPoint,
            _avoidedEmissions: avoidedEmissions(distance),
            heightProfile: heightProfile,
            region: MKCoordinateRegion(
                center: center,
                latitudinalMeters: northSouthReach + northSouthReach * 0.15,
                longitudinalMeters: eastWestReach + eastWestReach * 0.15
            ),
            track: coordinates
            )
    }

    /// Update the measurement in the measurement list and provide the updated list.
    private func update(measurement id: UInt64, syncState: UploadStatusType) -> [Measurement] {
        return measurements.map { measurement in
            if measurement.id == id {
                switch syncState {
                case .started:
                    return measurement.change(state: .synchronizing)
                default:
                    return measurement.change(state: .synchronized)
                }
            } else {
                return measurement
            }
        }
    }
}
