/*
 * Copyright 2023-2024 Cyface GmbH
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
import DataCapturing

/**
 View shown to the user, after a voucher has been claimed.

 This view shows the actual voucher code.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.2
 */
struct VoucherEnabled: View {
    /// The underlying view model containing the ability to load the actual voucher code from the voucher server.
    @ObservedObject var viewModel: VoucherViewModel

    var body: some View {
        if
            let voucher = viewModel.voucher {
            VStack {
                Divider()
                Text("Gutscheincode: \(voucher.code)")
                    .padding()
                Text("1x 15 Freiminuten auf die nächste Ausleihe in Schkeuditz - nextbike Nordsachsen")
                    .padding()
                //Text("gültig bis: \(dateFormatter.string(from: voucher.until))")
            }
        } else {
            // TODO: Better make this an error alert
            ErrorView(error: RFRError.missingVoucher)
        }
    }
}

#if DEBUG
var previewVoucherViewModel: VoucherViewModel {
    let ret = VoucherViewModel(
        authenticator: MockAuthenticator(),
        url: try! ConfigLoader.load().getIncentivesUrl(),
        dataStoreStack: MockDataStoreStack()
    )
    ret.voucher = Voucher(
        code: "abcdefg",
        until: "2023-12-31T23:59:59Z"
    )

    return ret
}

#Preview {
    VoucherEnabled(
        viewModel: previewVoucherViewModel
    )
}
#endif
