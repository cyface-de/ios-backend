//
//  VoucherViewModel.swift
//  RFR
//
//  Created by Klemens Muthmann on 05.06.23.
//

import Foundation
import DataCapturing
import SwiftUI

class VoucherViewModel: ObservableObject {
    private static let userDefaultsKey = "de.cyface.rfr.voucher"
    static let requiredKilometers = 15.0
    @Published var accumulatedKilometers = 0.0
    private let authenticator: Authenticator
    private let url: URL
    @Published var voucher: Voucher?
    @Published var voucherCount: Int = 0

    init(authenticator: Authenticator, url: URL) {
        self.authenticator = authenticator
        self.url = url
    }

    func onPressLoadVoucherButton() async throws {
        let vouchers = Vouchers(authenticator: authenticator, url: url)
        let voucher = try await vouchers.requestVoucher()

        let encoder = JSONEncoder()
        let data = try encoder.encode(voucher)
        UserDefaults.standard.set(data, forKey: VoucherViewModel.userDefaultsKey)
    }

    @MainActor
    func refreshModel() async throws {
        if accumulatedKilometers >= VoucherViewModel.requiredKilometers {
            if let data = UserDefaults.standard.data(forKey: VoucherViewModel.userDefaultsKey) {
                let decoder = JSONDecoder()
                voucher = try? decoder.decode(Voucher.self, from: data)
            }
        }

        let vouchers = Vouchers(authenticator: authenticator, url: url)

        Task {
            self.voucherCount = (try? await vouchers.count) ?? 0
        }
    }

    @ViewBuilder
    func view() -> some View {
        if voucherCount > 0 && accumulatedKilometers < VoucherViewModel.requiredKilometers {
            VoucherOverview(
                accumulatedKilometers: accumulatedKilometers,
                kilometersToAcquire: VoucherViewModel.requiredKilometers,
                voucherCount: voucherCount
            )
        } else if voucherCount > 0 && accumulatedKilometers >= VoucherViewModel.requiredKilometers && voucher == nil {
            VoucherReached(viewModel: self)
        } else if let voucher = voucher {
            VoucherEnabled(viewModel: self)
        } else {
            EmptyView()
        }
    }
}
