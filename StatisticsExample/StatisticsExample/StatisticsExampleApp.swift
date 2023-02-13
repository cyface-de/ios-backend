//
//  StatisticsExampleApp.swift
//  StatisticsExample
//
//  Created by Klemens Muthmann on 18.01.23.
//

import SwiftUI

@main
struct StatisticsExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: ViewModel())
        }
    }
}
