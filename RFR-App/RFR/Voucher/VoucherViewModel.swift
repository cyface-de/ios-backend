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
import Foundation
import DataCapturing
import SwiftUI

class VoucherViewModel: ObservableObject {
    @Published var accumulatedKilometers = 0.0
    @Published var voucher: Voucher?
    @Published var voucherCount: Int = 0
    private static let userDefaultsKey = "de.cyface.rfr.voucher"
    static let requiredKilometers = 15.0
    private let authenticator: Authenticator
    private let url: URL
    private let dataStoreStack: DataStoreStack

    init(authenticator: Authenticator, url: URL, dataStoreStack: DataStoreStack) {

        self.authenticator = authenticator
        self.url = url
        self.dataStoreStack = dataStoreStack
        let decoder = JSONDecoder()
        if let voucherData = UserDefaults.standard.data(forKey: VoucherViewModel.userDefaultsKey) {
            DispatchQueue.main.async { [weak self] in
                do {
                    self?.voucher = try decoder.decode(Voucher.self, from: voucherData)
                } catch {
                    fatalError()
                }
            }
        }
    }

    func onPressLoadVoucherButton() async throws {
        let vouchers = Vouchers(authenticator: authenticator, url: url)
        let voucher = try await vouchers.requestVoucher()

        let encoder = JSONEncoder()
        let data = try encoder.encode(voucher)
        UserDefaults.standard.set(data, forKey: VoucherViewModel.userDefaultsKey)
        UserDefaults.standard.synchronize()
        DispatchQueue.main.async {
            self.voucher = voucher
        }
    }

    @MainActor
    func refreshModel() async throws {
        if accumulatedKilometers >= VoucherViewModel.requiredKilometers {
            if let data = UserDefaults.standard.data(forKey: VoucherViewModel.userDefaultsKey) {
                let decoder = JSONDecoder()
                voucher = try? decoder.decode(Voucher.self, from: data)
            }
        } else {
            try dataStoreStack.wrapInContext { context in
                let request = MeasurementMO.fetchRequest()
                try request.execute().forEach { measurement in
                    let distanceInMeters = coveredDistance(tracks: measurement.typedTracks())
                    let distanceInKilometers = distanceInMeters / 1_000
                    accumulatedKilometers += distanceInKilometers
                }
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
            Spacer()
            VoucherOverview(
                viewModel: VoucherOverviewModel(
                        accumulatedKilometers: accumulatedKilometers,
                        kilometersToAcquire: VoucherViewModel.requiredKilometers,
                        voucherCount: voucherCount
                    )
            )
        } else if voucherCount > 0 && accumulatedKilometers >= VoucherViewModel.requiredKilometers && voucher == nil {
            Spacer()
            VoucherReached(viewModel: self)
        } else if voucher != nil {
            Spacer()
            VoucherEnabled(viewModel: self)
        } else {
            EmptyView()
        }
    }
}
