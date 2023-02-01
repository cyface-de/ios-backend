//
//  MeasurementCell.swift
//  RFR
//
//  Created by Klemens Muthmann on 27.01.23.
//

import SwiftUI

struct MeasurementCell: View {
    var viewModel: MeasurementCellViewModel

    var body: some View {
        VStack(alignment: .leading) {
            Text("\(viewModel.measurement.id)) \(viewModel.measurement.name)")
                .font(.headline)
            HStack {
                Text("\(viewModel.details)")
                Spacer()
                Image(systemName: viewModel.synchedSymbol)
                    .font(.subheadline)
            }
        }
    }
}

struct MeasurementCell_Previews: PreviewProvider {
    static var previews: some View {
        MeasurementCell(viewModel: MeasurementCellViewModel(measurement: exampleMeasurements[0]))
        MeasurementCell(viewModel: MeasurementCellViewModel(measurement: exampleMeasurements[1]))
    }
}
