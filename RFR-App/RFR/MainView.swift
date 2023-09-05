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
    @ObservedObject var viewModel: DataCapturingViewModel

    var body: some View {
        if let dataStoreStack = viewModel.dataStoreStack, let incentivesEndpoint = URL(string: RFRApp.incentivesUrl) {
            NavigationStack {
                VStack {
                    TabView(selection: $selectedTab) {
                        MeasurementsView(
                            viewModel: viewModel.measurementsViewModel,
                            voucherViewModel: VoucherViewModel(
                                authenticator: viewModel.syncViewModel.authenticator,
                                url: incentivesEndpoint,
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
                    ToolbarItem(placement: .principal) {
                        HStack {
                            Image("RFR-Logo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                            Spacer()
                        }
                    }

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

#if DEBUG
struct MainView_Previews: PreviewProvider {
    @State static var isAuthenticated = true
    static var previews: some View {
        MainView(
            viewModel: DataCapturingViewModel(
                isInitialized: false,
                showError: false,
                dataStoreStack: MockDataStoreStack()
            )
        )
    }
}
#endif
