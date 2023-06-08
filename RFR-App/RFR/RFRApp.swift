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

/**
 Entry point to the application showing the first view.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
@main
struct RFRApp: App {
    // TODO: Put this into some configuration file
    static let authenticationEndpoint = "https://s1-b.cyface.de/api/v3"
    static let uploadEndpoint = "https://s1-b.cyface.de/api/v3"
    static let registrationUrl = "https://s1-b.cyface.de/provider/api/v1/"
    static let incentivesUrl = "https://staging.cyface.de/incentives/api/v1/"
    @StateObject var appViewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            if appViewModel.isInitialized {
                if let loginViewModel = appViewModel.loginViewModel {
                    InitializationView(
                        loginViewModel: loginViewModel
                    )
                } else if let error = appViewModel.error {
                    ErrorView(error: error)
                }
            } else {
                LoadinScreen()
            }
        }
    }
}

/**
 * Required to handle errors during initialization of `LoginViewModel`.
 */
class AppViewModel: ObservableObject {
    var loginViewModel: LoginViewModel?
    var error: Error?
    @Published var isInitialized = false

    init() {
        Task {
            do {
                self.loginViewModel = try await LoginViewModel()
                DispatchQueue.main.async { [weak self] in
                    self?.isInitialized = true
                }
            } catch {
                self.error = error
            }
        }
    }
}
