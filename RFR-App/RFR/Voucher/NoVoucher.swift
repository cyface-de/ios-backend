//
//  NoEvent.swift
//  RFR
//
//  Created by Klemens Muthmann on 10.04.24.
//

import SwiftUI

struct NoVoucher: View {
    let voucherRedeemable: Bool
    var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        if let nextEvent = nextEvent() {
            Text("Nächste Gewinnaktion ab \(dateFormatter.string(from: nextEvent.lowerBound))")
        } else if voucherRedeemable {
            Text("Derzeit sind keine Gewinnaktionen verfügbar")
        } else {
            Text("Derzeit sind keine Gewinnaktionen geplant")
        }
    }
}

#Preview {
    NoVoucher(voucherRedeemable: true)
}

#Preview {
    NoVoucher(voucherRedeemable: false)
}
