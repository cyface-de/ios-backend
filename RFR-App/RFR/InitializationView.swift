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
import SwiftUI
import DataCapturing
import Combine
import OSLog
import AppAuthCore

struct InitializationView: View {
    @StateObject var viewModel: DataCapturingViewModel
    @StateObject var loginStatus = LoginStatus()
    let incentivesEndpoint: URL
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

#Preview {
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

#Preview {
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
