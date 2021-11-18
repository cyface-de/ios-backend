//
//  GeoLocationTrackDrawer.swift
//  Cyface
//
//  Created by Team Cyface on 23.09.19.
//  Copyright © 2019 Cyface GmbH. All rights reserved.
//

import Foundation
import DataCapturing
import MapKit
import os.log

/**
 

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 2.0.0
 */
class GeoLocationTrackDrawer: NSObject {

    private static let log = OSLog(subsystem: "MapViewController", category: "de.cyface")
    var polyline: MKPolyline?
    private static let regionRadius: CLLocationDistance = 1_000

    /**
     Creates a new

     - Parameter forMeasurementIdentifiedBy: The measurement identifier this drawer draws the track for
     */
    init(forMeasurementIdentifiedBy: Int64, on widget: MKMapView) {
        super.init()
        do {
            guard let coreDataStack = (UIApplication.shared.delegate as? AppDelegate)?.coreDataStack else {
                fatalError()
            }
            let persistenceLayer = PersistenceLayer(onManager: coreDataStack)
            persistenceLayer.context = persistenceLayer.makeContext()

            let measurement = try persistenceLayer.load(measurementIdentifiedBy: forMeasurementIdentifiedBy)

            guard let tracks = measurement.tracks?.array as? [Track] else {
                fatalError()
            }

            placeStartMarker(from: tracks, on: widget)
            placeEndMarker(from: tracks, on: widget)

            for track in tracks {
                guard let locations = track.locations?.array as? [GeoLocationMO] else {
                    fatalError()
                }

                guard !locations.isEmpty else {
                    let identifier = measurement.identifier
                    os_log("No locations to display in measurement %d!", log: GeoLocationTrackDrawer.log, type: .default, identifier)
                    continue
                }

                // Transform the location model objects from the database to a thread safe representation.
                var localLocations = [GeoLocation]()
                for location in locations {
                    localLocations.append(
                        GeoLocation(
                            latitude: location.lat,
                            longitude: location.lon,
                            accuracy: location.accuracy,
                            speed: location.speed,
                            timestamp: location.timestamp))
                }

                if let firstLocation = locations.first {
                    center(map: widget, onLocation: CLLocationCoordinate2D(latitude: firstLocation.lat, longitude: firstLocation.lon))
                }
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else {
                        return
                    }

                    self.draw(path: localLocations, on: widget)
                }
            }

        } catch let error {
            os_log("Unable to load locations! Error %{public}@", log: GeoLocationTrackDrawer.log, type: .error, error.localizedDescription)
        }
    }

    private func placeStartMarker(from tracks: [Track], on map: MKMapView) {
        guard let firstTrackLocation = tracks.first?.locations?.array.first as? GeoLocationMO else {
            return
        }

        let firstLocation = GeoLocation(
            latitude: firstTrackLocation.lat,
            longitude: firstTrackLocation.lon,
            accuracy: firstTrackLocation.accuracy,
            speed: firstTrackLocation.speed,
            timestamp: firstTrackLocation.timestamp)

        DispatchQueue.main.async {
            self.place(firstLocation, "Start", on: map)
        }
    }

    private func placeEndMarker(from tracks: [Track], on map: MKMapView) {
        guard let lastTrackLocation = tracks.last?.locations?.array.last as? GeoLocationMO else {
            return
        }

        let lastLocation = GeoLocation(
            latitude: lastTrackLocation.lat,
            longitude: lastTrackLocation.lon,
            accuracy: lastTrackLocation.accuracy,
            speed: lastTrackLocation.speed,
            timestamp: lastTrackLocation.timestamp)

        DispatchQueue.main.async {
            self.place(lastLocation, "End", on: map)
        }
    }

    private func center(map: MKMapView, onLocation location: CLLocationCoordinate2D) {
        let coordinateRegion = MKCoordinateRegion(
            center: location,
            latitudinalMeters: GeoLocationTrackDrawer.regionRadius,
            longitudinalMeters: GeoLocationTrackDrawer.regionRadius)
        map.setRegion(coordinateRegion, animated: true)
    }

    private func place(_ location: GeoLocation, _ title: String, on map: MKMapView) {
        map.addAnnotation(
            CyfaceAnnotation(
                title: title,
                coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)))
    }

    private func draw(path locations: [GeoLocation], on map: MKMapView) {
        var points = [CLLocationCoordinate2D]()
        for location in locations {
            points.append(CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
        }

        let polyline = MKPolyline(coordinates: &points, count: points.count)
        map.addOverlay(polyline)
        self.polyline = polyline
    }

    class CyfaceAnnotation: NSObject, MKAnnotation {
        let title: String?
        let coordinate: CLLocationCoordinate2D

        init(title: String, coordinate: CLLocationCoordinate2D) {
            self.title = title
            self.coordinate = coordinate

            super.init()
        }
    }
}

// MARK: - MKMapViewDelegate
extension GeoLocationTrackDrawer: MKMapViewDelegate {
    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 5
        return renderer
    }
}
