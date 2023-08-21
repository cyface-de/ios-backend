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
            VoucherOverview(
                viewModel: VoucherOverviewModel(
                        accumulatedKilometers: accumulatedKilometers,
                        kilometersToAcquire: VoucherViewModel.requiredKilometers,
                        voucherCount: voucherCount
                    )
            )
        } else if voucherCount > 0 && accumulatedKilometers >= VoucherViewModel.requiredKilometers && voucher == nil {
            VoucherReached(viewModel: self)
        } else if voucher != nil {
            VoucherEnabled(viewModel: self)
        } else {
            EmptyView()
        }
    }
}
