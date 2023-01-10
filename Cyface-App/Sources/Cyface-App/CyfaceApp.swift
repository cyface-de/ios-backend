/*
 * Copyright 2022 Cyface GmbH
 *
 * This file is part of the Cyface SDK for iOS.
 *
 * The Cyface SDK for iOS is free software: you can redistribute it and/or modify
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
import CoreMotion

@main
/// This is the entry point to the Cyface iOS application.
///
/// It starts the user interface and the backend as required simultaneously.
/// The backend is started via the ``appState``.
/// For further details see the documentation of the ``ApplicationState`` class.
/// The main UI is started via the Swift UI view ``ApplicationUI``.
/// That view is a kind of meta view, which decides, depending on the current `appState`, which view to show initially.
///
/// - author: Klemens Muthmann
/// - version: 1.0.0
/// - since: 4.0.0
struct CyfaceApp: App {

    /// The central application state which contains all values not specific to one view.
    @StateObject var appState = ApplicationState(settings: PropertySettings())

    /// Display the initial user interface
    var body: some Scene {
        WindowGroup {
            ApplicationUI(appState: appState).environmentObject(appState).tint(Color("Cyface-Green"))
        }
    }
}
