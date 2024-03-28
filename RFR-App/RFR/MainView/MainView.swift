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

/**
 The main application view allowing to switch subviews using a `TabView`.

 - Author: Klemens Muthmann
 - Version: 1.0.1
 - Since: 3.1.2
 */
struct MainView: View {
    // MARK: - Properties
    /// The view model managing all the local measurements.
    let measurementsViewModel: MeasurementsViewModel
    /// The view model handling data synchronization.
    let syncViewModel: SynchronizationViewModel
    /// The view model used during data capturing.
    let liveViewModel: LiveViewModel
    /// The view model checking for vouchers and providing enabled vouchers to the user interface.
    let voucherViewModel: VoucherViewModel
    /// The currently selected tab in this view.
    @State private var selectedTab = 2
    /// The most recent error if any occurred; `nil` otherwise.
    @State var error: Error?
    /// This is `true` if an error should be shown and `false` otherwise.
    var isShowingError: Binding<Bool> {
        Binding {
            error != nil
        } set: { _ in
            error = nil
        }
    }
    /// An authenticator used to manage the user profile.
    let authenticator: Authenticator

    var body: some View {
        NavigationStack {
            VStack {
                TabView(selection: $selectedTab) {
                    MeasurementsView(
                        viewModel: measurementsViewModel,
                        voucherViewModel: voucherViewModel
                    )
                    .tabItem {
                        Image(systemName: "list.bullet")
                        Text("Fahrten")
                            .font(.footnote)
                    }
                    .tag(1)
                    LiveView(
                        viewModel: liveViewModel
                    )
                    .tabItem {
                        Image(systemName: "location.fill")
                        Text("Live")
                    }
                    .tag(2)
                    StatisticsView(
                        viewModel: measurementsViewModel
                    )
                    .tabItem {
                        Image(systemName: "chart.xyaxis.line")
                        Text("Statistiken")
                            .font(.footnote)
                    }
                    .tag(3)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Show RFR Logo
                ToolbarItem(placement: .principal) {
                    RFRLogo()
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Show Submit Data action
                    SubmitDataButton(syncViewModel: syncViewModel)

                    // Show the menu with all the less important stuff, most users are not going to use.
                    MainMenu(error: $error, authenticator: authenticator)

                }
            }
        }
        .alert(
            "error",
            isPresented: isShowingError,
            presenting: error,
            actions: { error in
                // If you want buttons other than OK, add here
            }, message: { error in
                Text(error.localizedDescription)
            }
        )
    }
}

#if DEBUG
#Preview("Default") {
    @State var isAuthenticated = true
    let config = try! ConfigLoader.load()

    return MainView(
        measurementsViewModel: measurementsViewModel,
        syncViewModel: synchronizationViewModel,
        liveViewModel: liveViewModel,
        voucherViewModel: voucherViewModel,
        authenticator: MockAuthenticator()
    )
}

#Preview("Error Dialog") {
    let config = try! ConfigLoader.load()

    return MainView(
        measurementsViewModel: measurementsViewModel,
        syncViewModel: synchronizationViewModel,
        liveViewModel: liveViewModel,
        voucherViewModel: voucherViewModel,
        error: DataCapturingError.notRunning,
        authenticator: MockAuthenticator()
    )

}
#endif
