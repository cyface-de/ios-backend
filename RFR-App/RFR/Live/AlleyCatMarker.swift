//
//  AlleyCatMarker.swift
//  RFR
//
//  Created by Klemens Muthmann on 02.06.23.
//

import Foundation
import CoreLocation

struct AlleyCatMarker: Identifiable {
    let id = UUID()
    let location: CLLocationCoordinate2D
    let description: String
    let markerType: MarkerType
}

enum MarkerType {
    case start
    case standard
}
