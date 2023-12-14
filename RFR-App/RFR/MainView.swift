/*
 * Copyright 2023 Cyface GmbH
 *
 * This file is part of the Read-for-Robots iOS App.
 *
 * The Read-for-Robots iOS App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Read-for-Robots iOS App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Read-for-Robots iOS App. If not, see <http://www.gnu.org/licenses/>.
 */

import SwiftUI
import DataCapturing

/**
 The main application view allowing to switch subviews using a `TabView`.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
struct MainView: View {
    @State private var selectedTab = 2
    @State private var error: Error?
    @ObservedObject var viewModel: DataCapturingViewModel
    @EnvironmentObject var loginStatus: LoginStatus
    let incentivesUrl: URL

    var body: some View {
        if let error = error {
            ErrorView(error: error)
        } else {
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
                                viewModel: Measurements(coreDataStack: dataStoreStack)
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

                        // Show Submit Data action
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                Task {
                                    await viewModel.syncViewModel.synchronize()
                                }
                            }) {
                                VStack {
                                    Image(systemName: "icloud.and.arrow.up")
                                    Text("Daten übertragen")
                                        .font(.footnote)
                                }
                            }
                        }

                        // Show the menu with all the less important stuff, most users are not going to use.
                        ToolbarItem(placement: .navigationBarTrailing) {
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
                                VStack {
                                    Image(systemName: "person")
                                    Text("info", comment: "All menu entries")
                                        .font(.footnote)
                                }
                            }
                        }
                    }
                }
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                    Text("Error: Data Capturing Service was not yet initialized!")
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    @State var isAuthenticated = true
    let config = try! ConfigLoader.load()

    return MainView(
        viewModel: DataCapturingViewModel(
            isInitialized: false,
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
            uploadEndpoint: try! config.getUploadEndpoint()
        ), incentivesUrl: try! config.getIncentivesUrl()
    )
}
#endif
