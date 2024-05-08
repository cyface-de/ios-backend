/*
 * Copyright 2023-2024 Cyface GmbH
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
 - Version: 1.0.1
 - Since: 3.1.2
 */
@main
struct RFRApp: App {
    /// The application, which is required to store and load the authentication state of this application.
    @ObservedObject var appModel = AppModel()

    /// Setup Sentry tracing for the whole application.
    init() {
        let enableTracing = (try? appModel.config.getEnableSentryTracing()) ?? false
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
            if appModel.initialized {
                InitializationView(
                    measurementsViewModel: appModel.measurementsViewModel,
                    synchronizationViewModel: appModel.syncViewModel,
                    liveViewModel: appModel.liveViewModel,
                    voucherViewModel: appModel.voucherViewModel,
                    authenticator: appModel.authenticator)
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
 - Version: 1.0.2
 - Since: 3.1.2
 */
class AppModel: ObservableObject {
    // MARK: - Properties
    /// This applications configuration file.
    var config: Config = try! ConfigLoader.load()
    /// The view model used by the live view displayed while capturing data on the main view.
    let liveViewModel: LiveViewModel
    /// View model used to synchronize data to a Cyface Data Collector service.
    let syncViewModel: SynchronizationViewModel
    /// View model used to manage information about the complete collection of local measurements.
    let measurementsViewModel: MeasurementsViewModel
    /// View model used to manage voucher progress and download vouchers from a voucher server.
    var voucherViewModel: VoucherViewModel
    /// The authenticator used by this application to communicate with the Cyface Data Collector and the voucher server.
    let authenticator: Authenticator
    /// Tells the view about errors occuring during initialization.
    @Published var error: Error?
    /// A flag that is set to `true` if the initial setup process has completed.
    ///
    /// This flag is useful to avoid having an asynchronous initializer, which SwiftUI can not handle.
    @Published var initialized = false
    /// The UIKit Application Delegate required for functionality not yet ported to SwiftUI.
    /// Especially reacting to backround network requests needs to be handled here.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // MARK: - Initializers
    /// Start the setup process.
    ///
    /// Please refer to ``initialized`` to see if initialization has actually finished.
    init() {
        do {
            let clientId = config.clientId
            let uploadEndpoint = try config.getUploadEndpoint()
            let issuer = try config.getIssuerUri()
            let redirectURI = try config.getRedirectUri()
            let apiEndpoint = try config.getApiEndpoint()
            let incentivesUrl = try config.getIncentivesUrl()

            self.authenticator = AppModel.createAuthenticator(
                issuer: issuer,
                redirectURI: redirectURI,
                apiEndpoint: apiEndpoint,
                clientId: clientId
            )
            let dataStoreStack = try CoreDataStack()
            let uploadFactory = CoreDataBackedUploadFactory(dataStoreStack: dataStoreStack)
            let uploadProcessBuilder = BackgroundUploadProcessBuilder(
                sessionRegistry: PersistentSessionRegistry(dataStoreStack: dataStoreStack, uploadFactory: uploadFactory),
                collectorUrl: uploadEndpoint,
                uploadFactory: uploadFactory,
                dataStoreStack: dataStoreStack,
                authenticator: authenticator
            )

            measurementsViewModel = MeasurementsViewModel(
                dataStoreStack: dataStoreStack
            )
            liveViewModel = LiveViewModel(
                dataStoreStack: dataStoreStack,
                dataStorageInterval: 5.0,
                measurementsViewModel: measurementsViewModel
            )
            syncViewModel = SynchronizationViewModel(
                dataStoreStack: dataStoreStack,
                uploadProcessBuilder: uploadProcessBuilder,
                measurementsViewModel: measurementsViewModel
            )
            let voucherRequirements = VoucherRequirements(
                dataStoreStack: dataStoreStack
            )
            voucherViewModel = VoucherViewModel(
                vouchers: VouchersApi(
                        authenticator: authenticator,
                        url: incentivesUrl
                    ),
                voucherRequirements: voucherRequirements
            )

            Task {
                do {
                    try await dataStoreStack.setup()
                    appDelegate.delegate = uploadProcessBuilder

                    // Workaround to reupload previously failed uploads.
                    try dataStoreStack.wrapInContext { context in
                        let request = MeasurementMO.fetchRequest()
                        request.predicate = NSPredicate(format: "synchronized=false AND synchronizable=false")
                        let result = try request.execute()
                        for measurementModelObject in result {
                            measurementModelObject.synchronizable = true
                        }
                        try context.save()
                    }
                    try await measurementsViewModel.setup()

                    initialized = true
                } catch {
                    self.error = error
                }
            }
        } catch {
            fatalError("Unable to load Application")
        }
    }

    // MARK: - Methods
    /// A method to create the correct authenticator for either a testing or a production environment.
    private static func createAuthenticator(issuer: URL, redirectURI: URL, apiEndpoint: URL, clientId: String) -> Authenticator {
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
