//
//  InitializationView.swift
//  RFR
//
//  Created by Klemens Muthmann on 15.03.23.
//

import SwiftUI
import DataCapturing

struct InitializationView: View {
    @StateObject var viewModel = DataCapturingViewModel()
    @State private var loggedIn: Bool = false
    @State private var error: Error?
    let appDelegate: AppDelegate
    let sessionRegistry = SessionRegistry()

    var body: some View {
        if viewModel.isInitialized,
           let dataStoreStack = viewModel.dataStoreStack {

            Group {
                if loggedIn {
                    MainView(
                        viewModel: viewModel,
                        syncViewModel: SynchronizationViewModel(
                            dataStoreStack: dataStoreStack,
                            apiEndpoint: URL(string: RFRApp.uploadEndpoint)!,
                            sessionRegistry: sessionRegistry
                        )
                    )
                } else {
                    OAuthLoginView(appDelegate: appDelegate, loggedIn: $loggedIn, error: $error)

                }
            }

        } else if let error = viewModel.error {
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
                error: nil,
                dataStoreStack: MockDataStoreStack()
            ),
            appDelegate: AppDelegate()
        )
    }
}
#endif
