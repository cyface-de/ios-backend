//
//  InitializationView.swift
//  RFR
//
//  Created by Klemens Muthmann on 15.03.23.
//

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
