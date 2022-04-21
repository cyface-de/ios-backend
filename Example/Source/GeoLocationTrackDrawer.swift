/*
 * Copyright 2019-2022 Cyface GmbH
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
import MapKit
import os.log

/**
 

 - Author: Klemens Muthmann
 - Version: 1.0.1
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

            let measurement = try persistenceLayer.load(measurementIdentifiedBy: forMeasurementIdentifiedBy)

            let tracks = measurement.tracks
            placeStartMarker(from: tracks, on: widget)
            placeEndMarker(from: tracks, on: widget)

            for track in tracks {
                let locations = track.locations
                guard !locations.isEmpty else {
                    let identifier = measurement.identifier
                    os_log("No locations to display in measurement %d!", log: GeoLocationTrackDrawer.log, type: .default, identifier)
                    continue
                }

                if let firstLocation = locations.first {
                    center(map: widget, onLocation: CLLocationCoordinate2D(latitude: firstLocation.latitude, longitude: firstLocation.longitude))
                }
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else {
                        return
                    }

                    self.draw(path: locations, on: widget)
                }
            }

        } catch let error {
            os_log("Unable to load locations! Error %{public}@", log: GeoLocationTrackDrawer.log, type: .error, error.localizedDescription)
        }
    }

    private func placeStartMarker(from tracks: [Track], on map: MKMapView) {
        guard let firstTrackLocation = tracks.first?.locations.first else {
            return
        }

        DispatchQueue.main.async {
            self.place(firstTrackLocation, "Start", on: map)
        }
    }

    private func placeEndMarker(from tracks: [Track], on map: MKMapView) {
        guard let lastTrackLocation = tracks.last?.locations.last else {
            return
        }

        DispatchQueue.main.async {
            self.place(lastTrackLocation, "End", on: map)
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
