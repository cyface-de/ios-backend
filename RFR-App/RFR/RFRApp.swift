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
 Entry point to the application showing the first view.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
@main
struct RFRApp: App {

    /// The application, which is required to store and load the authentication state of this application.
    @StateObject var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            if let viewModel = appModel.viewModel, let incentivesUrl = appModel.incentivesUrl {
                InitializationView(viewModel: viewModel, incentivesEndpoint: incentivesUrl)
            } else if let error = appModel.error {
                ErrorView(error: error)
            } else {
                ProgressView()
            }
        }
    }
}

/**
 This class is used to receive errors during creation of the ``DataCapturingViewModel``.
 Those errors are published via the ``error`` property of this class.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
class AppModel: ObservableObject {
    @Published var viewModel: DataCapturingViewModel?
    /// Tells the view about errors occuring during initialization.
    @Published var error: Error?
    /// This applications configuration file.
    var config: Config?
    var incentivesUrl: URL?

    init() {
        do {
            let config = try ConfigLoader.load()
            let clientId = config.clientId
            let uploadEndpoint = try config.getUploadEndpoint()
            let issuer = try config.getIssuerUri()
            let redirectURI = try config.getRedirectUri()
            let apiEndpoint = try config.getApiEndpoint()
            self.incentivesUrl = try config.getIncentivesUrl()

            let authenticator = OAuthAuthenticator(
                issuer: issuer,
                redirectUri: redirectURI,
                apiEndpoint: apiEndpoint,
                clientId: clientId
            )
            self.viewModel = try DataCapturingViewModel(authenticator: authenticator, uploadEndpoint: uploadEndpoint)
        } catch {
            self.error = error
        }
    }
}
