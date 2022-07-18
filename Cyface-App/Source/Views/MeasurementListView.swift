//
//  MeasurementListView.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 01.07.22.
//

import SwiftUI

struct MeasurementListView: View {
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
                Image("error")
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
