//
//  VoucherOverview.swift
//  RFR
//
//  Created by Klemens Muthmann on 02.06.23.
//

import SwiftUI

struct VoucherOverview: View {
    let viewModel: VoucherOverviewModel
    @State var error: Error?

    var body: some View {
        if
            let accumulatedKilometers = try? viewModel.accumulatedKilometersLabel(),
            let kilometersToAcquire = try? viewModel.kilometersToAcquireLabel() {
            VStack {
                Divider()
                HStack {
                    Image(systemName: "rosette")
                    Text("Noch \(accumulatedKilometers) von \(kilometersToAcquire) km bis zum Gutschein").padding()
                }
                Divider()
                Text("\(viewModel.voucherCount) x 15 Minuten nextbike Gutscheine übrig").padding()
            }
        } else {
            ErrorView(error: RFRError.voucherOverviewFailed)
        }
    }
}

#if DEBUG
struct VoucherOverview_Previews: PreviewProvider {
    static var previews: some View {
        VoucherOverview(
            viewModel: VoucherOverviewModel(
                accumulatedKilometers: 15.0,
                kilometersToAcquire: 15.0,
                voucherCount: 25
            )
        )
    }
}
#endif
