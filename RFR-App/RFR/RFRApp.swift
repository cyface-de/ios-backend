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
import Sentry

/**
 Entry point to the application showing the first view.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.2
 */
@main
struct RFRApp: App {
    /// The application, which is required to store and load the authentication state of this application.
    @ObservedObject var appModel = AppModel()

    init() {
        let enableTracing = try! appModel.config.getEnableSentryTracing()
        SentrySDK.start { options in
            options.dsn = "https://cfb4e7e71da45d9d7fc312d2d350c951@o4506585719439360.ingest.sentry.io/4506585723437056"
            options.debug = false // Enabled debug when first installing is always helpful

            // Enable tracing to capture 100% of transactions for performance monitoring.
            // Use 'options.tracesSampleRate' to set the sampling rate.
            // We recommend setting a sample rate in production.
            options.enableTracing = enableTracing
        }
    }

    var body: some Scene {
        WindowGroup {
            if let viewModel = appModel.viewModel, let incentivesUrl = appModel.incentivesUrl {
                InitializationView(viewModel: viewModel, incentivesEndpoint: incentivesUrl)
                #if DEBUG
                    .transaction { transaction in
                    if CommandLine.arguments.contains("enable-testing") {
                        transaction.animation = nil
                    }
                }
                #endif
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
 - Version: 1.0.1
 - Since: 3.1.2
 */
class AppModel: ObservableObject {
    // MARK: - Properties
    /// The central view model branching of all the other view models required by the application.
    @Published var viewModel: DataCapturingViewModel?
    /// Tells the view about errors occuring during initialization.
    @Published var error: Error?
    /// The UIKit Application Delegate required for functionality not yet ported to SwiftUI.
    /// Especially reacting to backround network requests needs to be handled here.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    /// This applications configuration file.
    var config: Config = try! ConfigLoader.load()
    /// The internet address of the root of the incentives API.
    var incentivesUrl: URL?

    // MARK: - Initializers
    init() {
        do {
            let clientId = config.clientId
            let uploadEndpoint = try config.getUploadEndpoint()
            let issuer = try config.getIssuerUri()
            let redirectURI = try config.getRedirectUri()
            let apiEndpoint = try config.getApiEndpoint()
            self.incentivesUrl = try config.getIncentivesUrl()

            let dataStoreStack = try CoreDataStack()
            Task {
                do {
                    try await dataStoreStack.setup()

                    let authenticator = createAuthenticator(
                        issuer: issuer,
                        redirectURI: redirectURI,
                        apiEndpoint: apiEndpoint,
                        clientId: clientId
                    )
                    let uploadFactory = CoreDataBackedUploadFactory(dataStoreStack: dataStoreStack)
                    let uploadProcessBuilder = BackgroundUploadProcessBuilder(
                        sessionRegistry: PersistentSessionRegistry(dataStoreStack: dataStoreStack, uploadFactory: uploadFactory),
                        collectorUrl: uploadEndpoint,
                        uploadFactory: uploadFactory,
                        dataStoreStack: dataStoreStack,
                        authenticator: authenticator
                    )
                    appDelegate.delegate = uploadProcessBuilder
                    self.viewModel = try DataCapturingViewModel(authenticator: authenticator, uploadProcessBuilder: uploadProcessBuilder, dataStoreStack: dataStoreStack)
                } catch {
                    self.error = error
                }
            }
        } catch {
            self.error = error
        }
    }

    // MARK: - Methods
    /// A method to create the correct authenticator for either a testing or a production environment.
    private func createAuthenticator(issuer: URL, redirectURI: URL, apiEndpoint: URL, clientId: String) -> Authenticator {
        #if DEBUG
        if CommandLine.arguments.contains("enable-testing") {
            return MockAuthenticator()
        } else {
            return OAuthAuthenticator(
                issuer: issuer,
                redirectUri: redirectURI,
                apiEndpoint: apiEndpoint,
                clientId: clientId
            )
        }
        #else
        return OAuthAuthenticator(
            issuer: issuer,
            redirectUri: redirectURI,
            apiEndpoint: apiEndpoint,
            clientId: clientId
        )
        #endif
    }
}
