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

struct InitializationView: View {
    @StateObject var viewModel: DataCapturingViewModel
    @State private var loggedIn: Bool = false
    @State private var error: Error?
    let appDelegate: AppDelegate

    var body: some View {
        if viewModel.isInitialized {

            Group {
                if loggedIn {
                    MainView(
                        viewModel: viewModel
                    )
                } else {
                    OAuthLoginView(appDelegate: appDelegate, loggedIn: $loggedIn, error: $error)

                }
            }

        } else if let error = self.error {
            ErrorView(error: error)
        } else {
            LoadinScreen()
        }
    }
}

#if DEBUG
struct InitializationView_Previews: PreviewProvider {
    static var previews: some View {
        InitializationView(
            viewModel: DataCapturingViewModel(
                isInitialized: true,
                showError: false,
                dataStoreStack: MockDataStoreStack()
            ),
            appDelegate: AppDelegate()
        )
    }
}
#endif
