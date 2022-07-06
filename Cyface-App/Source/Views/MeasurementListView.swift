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
                Text("\(measurementViewModel.distance)")
            }


        }
            if measurementViewModel.synchronizing {
                ProgressView().padding()
            } else if measurementViewModel.synchronizationFailed {
                Image("error").padding()
            } else {
                EmptyView().padding()
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
    }
}
