//
//  VoucherReached.swift
//  RFR
//
//  Created by Klemens Muthmann on 02.06.23.
//

import SwiftUI

struct VoucherReached: View {
    let viewModel: VoucherViewModel
    @State var error: Error?

    var body: some View {
        if let error = error {
            ErrorView(error: error)
        } else {
            VStack {
                Divider()
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                    Text("nextbike Gutschein freigeschaltet")
                        .padding()
                }
                Button(action: {
                    Task {
                        do {
                            try await viewModel.onPressLoadVoucherButton()
                        } catch {
                            self.error = error
                        }
                    }
                }, label: {
                    Text("Gutschein anzeigen")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(Color("ButtonText"))

                }
                )
            }
            .buttonStyle(.borderedProminent)
            .padding([.trailing, .leading])
        }
    }
}

struct VoucherReached_Previews: PreviewProvider {
    static var previews: some View {
        VoucherReached(
            viewModel: VoucherViewModel(
                authenticator: MockAuthenticator(),
                url: URL(string: RFRApp.incentivesUrl)!
            )
        )
    }
}
