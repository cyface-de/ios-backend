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
 * The Cyface SDK for iOS is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Cyface SDK for iOS. If not, see <http://www.gnu.org/licenses/>.
 */
import SwiftUI
import CoreLocation
import MapKit

struct MainMap: View {
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.5515, longitude: 12.2388), span: MKCoordinateSpan( latitudeDelta: 0.9, longitudeDelta: 0.9))

    var body: some View {
        Map(
            coordinateRegion: $region,
            showsUserLocation: true,
            userTrackingMode: .constant(.follow)
        )
    }
}

#if DEBUG
struct MainMap_Previews: PreviewProvider {
    static var previews: some View {
        MainMap()
    }
}
#endif
