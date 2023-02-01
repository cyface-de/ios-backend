//
//  Overview.swift
//  RFR
//
//  Created by Klemens Muthmann on 26.01.23.
//

import SwiftUI

struct MeasurementsView: View {
    var measurements: [Measurement]

    var body: some View {
        NavigationStack {
            List {
                    ForEach(measurements) {measurement in
                        NavigationLink(destination: MeasurementView(viewModel: MeasurementViewViewModel())) {
                            MeasurementCell(viewModel: MeasurementCellViewModel(measurement: measurement))
                        }
                    }
                    .navigationTitle("Fahrten")
            }
        }
    }
}

struct MeasurementsView_Previews: PreviewProvider {
    static var previews: some View {
        MeasurementsView(measurements: exampleMeasurements)
    }
}
