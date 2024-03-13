/*
 * Copyright 2023 Cyface GmbH
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
    /// The view model backing the main application view.
    @ObservedObject var viewModel: DataCapturingViewModel
    /// The current login status. This is a wrapper for a simple boolean, making it easier to pass into the environment. If it is false, the login screen is shown again.
    /// Having this here is required to change the value if the user presses on `log out`.
    @EnvironmentObject var loginStatus: LoginStatus
    // TODO: This should probably not be a property here. Maybe try to create the VoucherViewModel as part of the voucher view, loading the seetings directly there.
    /// The internet address to the root of the incentives API.
    let incentivesUrl: URL

    var body: some View {
        if let dataStoreStack = viewModel.dataStoreStack {
            NavigationStack {
                VStack {
                    TabView(selection: $selectedTab) {
                        MeasurementsView(
                            viewModel: viewModel.measurementsViewModel,
                            voucherViewModel: VoucherViewModel(
                                authenticator: viewModel.syncViewModel.authenticator,
                                url: incentivesUrl,
                                dataStoreStack: dataStoreStack
                            )
                        )
                        .tabItem {
                            Image(systemName: "list.bullet")
                            Text("Fahrten")
                                .font(.footnote)
                        }
                        .tag(1)
                        LiveView(
                            viewModel: viewModel.liveViewModel
                        )
                        .tabItem {
                            Image(systemName: "location.fill")
                            Text("Live")
                        }
                        .tag(2)
                        StatisticsView(
                            viewModel: viewModel.measurementsViewModel
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
                        HStack {
                            // This is an ugly workaround from Stackoverflow.
                            // Appaerantly it is impossible to scale the logo correctly any other way.
                            Text("Logo")
                                .font(.title)
                                .foregroundStyle(.clear)
                                .overlay {
                                    Image("RFR-Logo")
                                        .resizable()
                                        .scaledToFill()
                                        .padding(.leading)
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Logo")
                            Spacer()
                        }
                    }

                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        // Show Submit Data action
                        Button(action: {
                            Task {
                                await viewModel.syncViewModel.synchronize()
                            }
                        }) {
                            Label("Daten übertragen", systemImage: "icloud.and.arrow.up")
                                .labelStyle(.titleAndIcon)
                        }

                        // Show the menu with all the less important stuff, most users are not going to use.
                        Menu {
                            NavigationLink(destination: {
                                ProfileView(authenticator: viewModel.authenticator)
                            }) {
                                VStack {
                                    Image(systemName: "person")
                                    Text("Profil").font(.footnote)
                                }
                            }
                            NavigationLink(destination: {ImpressumView()}) {
                                VStack {
                                    Image(systemName: "info.circle")
                                    Text("Impressum").font(.footnote)
                                }
                            }
                            Button(
                                action: {
                                    Task {
                                        do {
                                            try await viewModel.authenticator.logout()
                                            loginStatus.isLoggedIn = false
                                        } catch {
                                            self.error = error
                                        }
                                    }
                                }) {
                                    VStack {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                        Text("Abmelden").font(.footnote)
                                    }
                                }
                        } label: {
                            Label("info",systemImage: "ellipsis")
                                .labelStyle(.titleAndIcon)
                        }
                    }
                }
            }
            .alert(
                "error",
                isPresented: isShowingError,
                presenting: error) { error in
                    // If you want buttons other than OK, add here
                } message: { error in
                    Text(error.localizedDescription)
                }
        } else {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                Text("Error: Data Capturing Service was not yet initialized!")
            }
        }
    }
}

#if DEBUG
#Preview("Default") {
    @State var isAuthenticated = true
    let config = try! ConfigLoader.load()

    return MainView(
        viewModel: DataCapturingViewModel(
            showError: false,
            dataStoreStack: MockDataStoreStack(
                persistenceLayer: MockPersistenceLayer(
                    measurements: [
                        FinishedMeasurement(identifier: 0),
                        FinishedMeasurement(identifier: 1),
                        FinishedMeasurement(identifier: 2)
                    ]
                )
            ),
            authenticator: MockAuthenticator(),
            collectorUrl: try! config.getUploadEndpoint()
        ), incentivesUrl: try! config.getIncentivesUrl()
    )
}

#Preview("Error Dialog") {
    let config = try! ConfigLoader.load()

    return MainView(
        error: DataCapturingError.notRunning,
        viewModel: DataCapturingViewModel(
            showError: false,
            dataStoreStack: MockDataStoreStack(
                persistenceLayer: MockPersistenceLayer(
                    measurements: [
                        FinishedMeasurement(identifier: 0),
                        FinishedMeasurement(identifier: 1),
                        FinishedMeasurement(identifier: 2)
                    ]
                )
            ),
            authenticator: MockAuthenticator(),
            collectorUrl: try! config.getUploadEndpoint()
        ),
        incentivesUrl: try! config.getIncentivesUrl()
    )

}
#endif
