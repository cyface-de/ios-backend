//
//  MainMap.swift
//  RFR
//
//  Created by Klemens Muthmann on 20.06.23.
//

import SwiftUI
import CoreLocation
import MapKit

struct MainMap: View {
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.5515, longitude: 12.2388), span: MKCoordinateSpan( latitudeDelta: 0.9, longitudeDelta: 0.9))
    @State var markers = [AlleyCatMarker]()

    var body: some View {
        Map(
            coordinateRegion: $region,
            showsUserLocation: true,
            userTrackingMode: .constant(.follow),
            annotationItems: markers
        ) { marker in
            MapAnnotation(coordinate: marker.location) {
                Circle()
                    .foregroundColor((.start == marker.markerType) ? Color.blue : Color.red)
                Text(marker.description)
                    .background(.white.opacity(0.7))
            }
        }
        .onAppear {
            let schkeuditzData = loadAlleyCatData(fileName: "schkeuditz", ext: "csv")
            let köthenData = loadAlleyCatData(fileName: "köthen", ext: "csv")

            self.markers.append(contentsOf: schkeuditzData)
            self.markers.append(contentsOf: köthenData)
        }
    }
}

#if DEBUG
struct MainMap_Previews: PreviewProvider {
    static var previews: some View {
        MainMap()
    }
}
#endif
