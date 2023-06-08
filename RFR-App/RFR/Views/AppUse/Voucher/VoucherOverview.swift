//
//  VoucherOverview.swift
//  RFR
//
//  Created by Klemens Muthmann on 02.06.23.
//

import SwiftUI

struct VoucherOverview: View {
    let accumulatedKilometers: Double
    let kilometersToAcquire: Double
    let voucherCount: Int

    var body: some View {
        VStack {
            Divider()
            HStack {
                Image(systemName: "rosette")
                Text("Noch \(accumulatedKilometers) von \(kilometersToAcquire) km bis zum Gutschein").padding()
            }
            Divider()
            Text("\(voucherCount) x 15 Minuten nextbike Gutscheine übrig").padding()
        }
    }
}

struct VoucherOverview_Previews: PreviewProvider {
    static var previews: some View {
        VoucherOverview(
            accumulatedKilometers: 15.0,
            kilometersToAcquire: 15.0,
            voucherCount: 25
        )
    }
}
