/*
 * Copyright 2024 Cyface GmbH
 *
 * This file is part of the Ready for Robots App.
 *
 * The Ready for Robots App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Ready for Robots App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Ready for Robots App. If not, see <http://www.gnu.org/licenses/>.
 */

import SwiftUI

/**
The view shown if no voucher has been enabled.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.2.2
 */
struct NoVoucher: View {
    /// `true` if a voucher may be redeemed; `false` otherwise.
    let voucherRedeemable: Bool
    /// Formatter used to display dates in this view.
    var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        if let nextEvent = nextEvent() {
            Text(
                String.localizedStringWithFormat(
                    NSLocalizedString(
                        "de.cyface.rfr.text.NoVoucher.next_event",
                        comment: "Label telling the user when the next event happens. The date is provided as the first arguemnt."
                    ), dateFormatter.string(from: nextEvent.lowerBound)
                )
            ) // "Nächste Gewinnaktion ab \(dateFormatter.string(from: nextEvent.lowerBound))"
        } else if voucherRedeemable {
            Text("de.cyface.rfr.text.NoVoucher.no_events", comment: "Label telling the user that there are no events at the moment.") //Derzeit sind keine Gewinnaktionen verfügbar
        } else {
            Text("de.cyface.rfr.text.NoVoucher.nothing_planned", comment: "Label telling the user that there are no events planned.") // Derzeit sind keine Gewinnaktionen geplant
        }
    }
}

#Preview {
    NoVoucher(voucherRedeemable: true)
}

#Preview {
    NoVoucher(voucherRedeemable: false)
}
