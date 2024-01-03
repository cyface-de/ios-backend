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
import Combine
import OSLog
import AppAuthCore

/**
 The first view shown after starting the application. This should usually be the login link or some error message if startup failed.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.2
 */
struct InitializationView: View {
    /// The central view model forking of all the sub models.
    @StateObject var viewModel: DataCapturingViewModel
    /// The applications login status, which is a wrapped boolean for easy storage to the environment.
    /// Based on this flag, this view either shows the login link or forwards to the ``MainView``.
    @StateObject var loginStatus = LoginStatus()
    // TODO: This should probably loaded from config at the MeasurementsView.
    /// The internet address of the root of the incentives API
    let incentivesEndpoint: URL
    /// Allows the login process to deep link back to the login page.
    @State var loginNavigationState: [String] = []

    var body: some View {
        if viewModel.isInitialized && loginStatus.isLoggedIn {
            MainView(
                viewModel: viewModel,
                incentivesUrl: incentivesEndpoint
            )
            .environmentObject(loginStatus)

        } else if viewModel.isInitialized && !loginStatus.isLoggedIn {
            NavigationStack(path: $loginNavigationState) {
                OAuthLoginView(
                    authenticator: viewModel.authenticator,
                    errors: $loginNavigationState
                )
                .onOpenURL(perform: { url in
                    viewModel.authenticator.callback(url: url)
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
        } else {
            LoadinScreen()
        }
    }
}

#if DEBUG
let config = try! ConfigLoader.load()

#Preview("Standard") {
    return InitializationView(
        viewModel: DataCapturingViewModel(
            isInitialized: true,
            showError: false,
            dataStoreStack: MockDataStoreStack(
                persistenceLayer: MockPersistenceLayer(measurements: [
                    FinishedMeasurement(identifier: 0),
                    FinishedMeasurement(identifier: 1),
                    FinishedMeasurement(identifier: 2)
                ])
            ),
            authenticator: MockAuthenticator(),
            uploadEndpoint: try! config.getUploadEndpoint()
        ),
        incentivesEndpoint: try! config.getIncentivesUrl()
    )
}

#Preview("Error") {
    return InitializationView(
        viewModel: DataCapturingViewModel(
            isInitialized: true,
            showError: false,
            dataStoreStack: MockDataStoreStack(
                persistenceLayer: MockPersistenceLayer(
                    measurements: []
                )
            ),
            authenticator: MockAuthenticator(),
            uploadEndpoint: try! config.getUploadEndpoint()),
        incentivesEndpoint: try! config.getIncentivesUrl(),
        loginNavigationState: ["test"]
    )
}
#endif
