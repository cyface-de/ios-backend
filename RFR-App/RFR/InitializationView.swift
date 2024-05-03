/*
 * Copyright 2023-2024 Cyface GmbH
 *
 * This file is part of the Ready for Robots iOS App.
 *
 * The Ready for Robots iOS App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Ready for Robots iOS App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Ready for Robots iOS App. If not, see <http://www.gnu.org/licenses/>.
 */
import SwiftUI
import DataCapturing
import Combine
import OSLog
import AppAuthCore

/**
 The first view shown after starting the application. This should usually be the login link or some error message if startup failed.

 - Author: Klemens Muthmann
 - Version: 1.0.2
 - Since: 3.1.2
 */
struct InitializationView: View {
    /// The applications login status, which is a wrapped boolean for easy storage to the environment.
    /// Based on this flag, this view either shows the login link or forwards to the ``MainView``.
    @StateObject var loginStatus = LoginStatus()
    /// Allows the login process to deep link back to the login page.
    @State var loginNavigationState: [String] = []
    /// A view model to handle all the locally captured measurements
    let measurementsViewModel: MeasurementsViewModel
    /// A view model to handle uploading local measurements to a Cyface Data Collector Server
    let synchronizationViewModel: SynchronizationViewModel
    /// A view model to handle live data capturing.
    let liveViewModel: LiveViewModel
    /// A view model to manage voucher creation and display.
    let voucherViewModel: VoucherViewModel
    /// An authenticator to authenticate and authorize a user for communication with the Data Collector and the Voucher service.
    let authenticator: Authenticator

    var body: some View {
        if loginStatus.isLoggedIn {
            MainView(
                measurementsViewModel: measurementsViewModel,
                syncViewModel: synchronizationViewModel,
                liveViewModel: liveViewModel,
                voucherViewModel: voucherViewModel,
                authenticator: authenticator
            )
            .environmentObject(loginStatus)

        } else {
            NavigationStack(path: $loginNavigationState) {
                OAuthLoginView(
                    authenticator: authenticator,
                    errors: $loginNavigationState
                )
                .onOpenURL(perform: { url in
                    authenticator.callback(url: url)
                })
                .environmentObject(loginStatus)
                .navigationTitle(String(
                    localized: "login",
                    comment: "Labels the login action"
                ))
                .navigationDestination(for: String.self) { errorMessage in
                    ErrorTextView(errorMessage: errorMessage)
                }
            }
        }
    }
}

#if DEBUG
let config = try! ConfigLoader.load()
let mockDataStoreStack = MockDataStoreStack()
let measurementsViewModel = MeasurementsViewModel(dataStoreStack: mockDataStoreStack)
let mockUploadFactory = MockUploadFactory()
let authenticator = StaticAuthenticator()
let incentivesUrl = URL(string: config.incentivesUrl)!
let uploadProcessBuilder = DefaultUploadProcessBuilder(
    collectorUrl: URL(string: "https://localhost:8080/api/v4")!,
    sessionRegistry: DefaultSessionRegistry(),
    uploadFactory: MockUploadFactory(),
    authenticator: authenticator
)

let synchronizationViewModel = SynchronizationViewModel(
    dataStoreStack: mockDataStoreStack,
    uploadProcessBuilder: uploadProcessBuilder,
    measurementsViewModel: measurementsViewModel
)

let liveViewModel = LiveViewModel(
    dataStoreStack: mockDataStoreStack,
    dataStorageInterval: 5.0,
    measurementsViewModel: measurementsViewModel
)

let voucherViewModel2 = VoucherViewModel(
    vouchers: MockVouchers(count: 3, voucher: Voucher(code: "test-voucher")),
    voucherRequirements: VoucherRequirements(dataStoreStack: mockDataStoreStack)
)

#Preview("Standard") {
    return InitializationView(
        measurementsViewModel: measurementsViewModel,
        synchronizationViewModel: synchronizationViewModel,
        liveViewModel: liveViewModel,
        voucherViewModel: voucherViewModel2,
        authenticator: authenticator
    )
}

#Preview("Error") {
    return InitializationView(
        loginNavigationState: ["test"], 
        measurementsViewModel: measurementsViewModel,
        synchronizationViewModel: synchronizationViewModel,
        liveViewModel: liveViewModel,
        voucherViewModel: voucherViewModel2,
        authenticator: authenticator
    )
}
#endif
