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

import SwiftUI

/**
 A single list entry in the list of measurements, showing a general overview of the measurement.

 - author: Klemens Muthmann
 - version: 1.0.0
 */
struct MeasurementListView: View {
    /// The view model containing the current data of the measurement and handling connection to data storage.
    @Binding var measurementViewModel: MeasurementViewModel

    var body: some View {
        HStack {
        VStack {
            HStack {
                Text("Measurement \(measurementViewModel.id)")
                Spacer()
            }

            HStack {
                Text("Distance")
                Spacer()
                Text("\(measurementViewModel.formattedDistance)")
            }


        }
            if measurementViewModel.synchronizing {
                ProgressView()
                    .padding()
                    .frame(width: 50, height: 50, alignment: .center)
            } else if measurementViewModel.synchronizationFailed {
                Image(systemName: "exclamationmark.triangle.fill")
                    .resizable()
                    .padding()
                    .frame(width: 50, height: 50, alignment: .center)
            } else {
                ProgressView()
                    .padding()
                    .hidden()
                    .frame(width: 50, height: 50, alignment: .center)
            }
        }
    }
}

struct MeasurementListView_Previews: PreviewProvider {
    static var previews: some View {
        let measurementViewModel = MeasurementViewModel(distance: 10.0, id: 2)
        MeasurementListView(measurementViewModel: .constant(measurementViewModel))

        let synchronizingViewModel = MeasurementViewModel(synchronizing: true, distance: 10.0, id: 2)
        MeasurementListView(measurementViewModel: .constant(synchronizingViewModel))

        let synchronizationFailedViewModel = MeasurementViewModel(synchronizationFailed: true, distance: 10.0, id: 2)
        MeasurementListView(measurementViewModel: .constant(synchronizationFailedViewModel))

        MeasurementListView(measurementViewModel: .constant(MeasurementViewModel(distance: 2364.82374, id: 4)))
    }
}
