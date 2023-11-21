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
    @State private var error: Error?
    let incentivesEndpoint: URL

    var body: some View {
        if let error = self.error {
            ErrorView(error: error)
        } else if viewModel.isInitialized {

            Group {
                if loginStatus.isLoggedIn {
                    MainView(
                        viewModel: viewModel,
                        incentivesUrl: incentivesEndpoint
                    )
                } else {
                    OAuthLoginView(
                        authenticator: viewModel.authenticator,
                        error: $error
                    )
                    .onOpenURL(perform: { url in
                        viewModel.authenticator.callback(url: url)
                    })
                }
            }
            .environmentObject(loginStatus)

        } else {
            LoadinScreen()
        }
    }
}

#if DEBUG
#Preview {
    var config = try! ConfigLoader.load()

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
#endif
