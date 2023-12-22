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
import Foundation
import DataCapturing
import SwiftUI

/**
 View model used for the view showing the voucher.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.2
 */
class VoucherViewModel: ObservableObject {
    // MARK: - Private Properties
    /// A retrieved voucher is stored to user defaults under this key.
    private static let userDefaultsKey = "de.cyface.rfr.voucher"
    /// This is the amount of kilometers the participant must have driven, to acquire a voucher.
    static let requiredKilometers = 15.0
    // MARK: - Properties
    /// The currently accumulated kilometers by the participant.
    @Published var accumulatedKilometers = 0.0
    /// The acquired voucher or `nil` if no voucher has been acquired yet.
    @Published var voucher: Voucher?
    /// The number of available fouchers, shown as long as the current user did not acquire a voucher already.
    @Published var voucherCount: Int = 0
    /// The authenticator to authenticate with the Ready for Robots identity provider.
    private let authenticator: Authenticator
    /// The internet address of the root of the voucher API used by this application.
    private let url: URL
    /// Stack to a data store to retrieve measurement information for calculating the covered distance by this user.
    private let dataStoreStack: DataStoreStack

    // MARK: - Initializers
    /// Create a new object of this class, communicating with the voucher API at the provided `url`, authenticating with the provided `authenticator`.
    /// - Parameter dataStoreStack: Used to retrieve the covered distance by this user.
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

    // MARK: - Methods
    /// Handle a press on the 'load vouchers' button, loading a voucher.
    ///
    /// - Throws: If communication with the server fails or no vouchers are available anymore.
    /// Please have a look a the voucher API documentation and ``VoucherRequestError`` to get information about the meaning of the different HTTP Status codes returned.
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

    /// Refresh the state from user defaults and the local database.
    ///
    /// - Throws: If the local storage was not available.
    /// If this happens something is seriously wrong with the app installation.
    /// It is usually not possible to recover from such an error.
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
                    let distanceInMeters = Statistics.coveredDistance(tracks: measurement.typedTracks())
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

    /// Create the correct view for the current progress in acquiring a voucher.
    /// At first show the amount of vouchers available and the progress towards acquiring one.
    /// Thereafter show a button to acquire a voucher and finally show the voucher itself if one was still available.
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
