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
import DataCapturing

struct VoucherEnabled: View {
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
            ErrorView(error: RFRError.missingVoucher)
        }
    }
}

#if DEBUG
struct VoucherEnabled_Previews: PreviewProvider {
    static var viewModel: VoucherViewModel {
        let ret = VoucherViewModel(
            authenticator: MockAuthenticator(),
            url: try! ConfigLoader.load().getIncentivesUrl(),
            dataStoreStack: MockDataStoreStack(
                persistenceLayer: MockPersistenceLayer(
                    measurements: [
                        FinishedMeasurement(identifier: 0),
                        FinishedMeasurement(identifier: 1),
                        FinishedMeasurement(identifier: 2)
                    ]
                )
            )
        )
        ret.voucher = Voucher(
            code: "abcdefg",
            until: "2023-12-31T23:59:59Z"
        )

        return ret
    }

    static var previews: some View {
        VoucherEnabled(
            viewModel: viewModel
        )
    }
}
#endif
