//
//  Cyface_AppApp.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 25.03.22.
//

import SwiftUI

@main
struct CyfaceApp: App {

    @StateObject var appState = ApplicationState(settings: PropertySettings())

    var body: some Scene {
        WindowGroup {
            ApplicationUI().environmentObject(appState)
        }
    }
}
