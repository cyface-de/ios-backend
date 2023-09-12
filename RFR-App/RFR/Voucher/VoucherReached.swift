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

#if DEBUG
struct VoucherReached_Previews: PreviewProvider {
    static var previews: some View {
        VoucherReached(
            viewModel: VoucherViewModel(
                authenticator: MockAuthenticator(),
                url: URL(string: RFRApp.incentivesUrl)!,
                dataStoreStack: MockDataStoreStack()
            )
        )
    }
}
#endif
