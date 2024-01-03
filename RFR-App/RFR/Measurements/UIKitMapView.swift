/*
 * Copyright 2023 Cyface GmbH
 *
 * This file is part of the Ready for Robots App.
 *
 * The Ready for Robots App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Ready for Robots App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Ready for Robots App. If not, see <http://www.gnu.org/licenses/>.
 */
// TODO: Remove this as soon as Swift UI supports polylines
// Based on: https://codakuma.com/the-line-is-a-dot-to-you/

import SwiftUI
import MapKit

// TODO: Make this draw multiple lines, so that we can show pauses in a measurement.
/**
 Allows to show a line within a map event though this is not yet supported by SwiftUI.

 It is a *UIKit* adapter to show an old *UIKit* MapView, containing a polyline.
 This is necessary to display tracks.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.2
 */
struct MapView: UIViewRepresentable {
    /// The region on the map to show by this view.
  let region: MKCoordinateRegion
    /// The line to draw on the map
  let lineCoordinates: [CLLocationCoordinate2D]

    /// Create the actual *UIKit* map view.
  func makeUIView(context: Context) -> MKMapView {
    let mapView = MKMapView()
    mapView.delegate = context.coordinator
    mapView.region = region

    let polyline = MKPolyline(coordinates: lineCoordinates, count: lineCoordinates.count)
    mapView.addOverlay(polyline)

    return mapView
  }

    /// Nothing to do on this implementation, but required by the `UIViewRepresentable` protocol
  func updateUIView(_ view: MKMapView, context: Context) {}

    /// Create the delegate called by the underlying *UIKit* view controller.
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

}

/**
The delegate used by the *UIKit* view to handle events.

 This implements an `MKMapViewDelegate` to implement events on a `MKMapView`, specifically drawing a line.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.2
 */
class Coordinator: NSObject, MKMapViewDelegate {
    /// The parent ``MapView`` as a back reference.
  var parent: MapView

    /// Create a new object of this class, with the provided parent.
  init(_ parent: MapView) {
    self.parent = parent
  }

    /// Delegate method used to draw the acutal line on the Map.
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    if let routePolyline = overlay as? MKPolyline {
      let renderer = MKPolylineRenderer(polyline: routePolyline)
      renderer.strokeColor = UIColor.systemBlue
      renderer.lineWidth = 10
      return renderer
    }
    return MKOverlayRenderer()
  }
}
