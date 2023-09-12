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
 * The Cyface SDK for iOS is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Cyface SDK for iOS. If not, see <http://www.gnu.org/licenses/>.
 */
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
