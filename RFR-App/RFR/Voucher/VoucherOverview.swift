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
 A view displaying an overview of the state of reaching a NextBike Voucher.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.2
 */
struct VoucherOverview: View {
    /// The underlying view model containing the current voucher progress and connection to the voucher server.
    let viewModel: VoucherOverviewModel
    /// An error if one occurred `nil` otherwise.
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
            // TODO: Would be better to make an alert from this.
            ErrorView(error: RFRError.voucherOverviewFailed)
        }
    }
}

#if DEBUG
#Preview {
    VoucherOverview(
        viewModel: VoucherOverviewModel(
            accumulatedKilometers: 15.0,
            kilometersToAcquire: 15.0,
            voucherCount: 25
        )
    )
}
#endif
