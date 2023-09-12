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
    static let uploadEndpoint = "https://s2-b.cyface.de/api/v4"
    static let incentivesUrl = "https://staging.cyface.de/incentives/api/v1/"
    @UIApplicationDelegateAdaptor(RFR.AppDelegate.self) var appDelegate
    @ObservedObject var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            if let viewModel = appModel.viewModel {
                InitializationView(viewModel: viewModel, appDelegate: appDelegate)
            } else if let error = appModel.error {
                ErrorView(error: error)
            } else {
                ProgressView()
            }
        }
    }
}

class AppModel: ObservableObject {
    @Published var viewModel: DataCapturingViewModel?
    @Published var error: Error?

    init() {
        do {
            self.viewModel = try DataCapturingViewModel()
        } catch {
            self.error = error
        }
    }
}
