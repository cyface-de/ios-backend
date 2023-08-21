//
//  VoucherEnabled.swift
//  RFR
//
//  Created by Klemens Muthmann on 02.06.23.
//

import SwiftUI

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
            url: URL(string: RFRApp.incentivesUrl)!,
            dataStoreStack: MockDataStoreStack()
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
