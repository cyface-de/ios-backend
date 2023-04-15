//
//  InitializationView.swift
//  RFR
//
//  Created by Klemens Muthmann on 15.03.23.
//

import SwiftUI
import DataCapturing

struct InitializationView: View {
    @StateObject var viewModel: DataCapturingViewModel
    @StateObject var loginViewModel: LoginViewModel
    @State private var isAuthenticated = false

    var body: some View {
        if viewModel.isInitialized, let apiUrl = URL(string: RFRApp.uploadEndpoint), let authenticator = loginViewModel.authenticator, let dataStoreStack = viewModel.dataCapturingService?.dataStoreStack {

            if isAuthenticated {
                MainView(
                    isAuthenticated: $isAuthenticated,
                    viewModel: viewModel,
                    syncViewModel: SynchronizationViewModel(
                        synchronizer: CyfaceSynchronizer(
                            apiURL: apiUrl,
                            dataStoreStack: dataStoreStack,
                            cleaner: AccelerationPointRemovalCleaner(),
                            authenticator: authenticator
                        )
                    )
                )
            } else {
                LoginView(
                    viewModel: loginViewModel, isAuthenticated: $isAuthenticated
                )
            }

        } else {
            if let error = viewModel.error {
                ErrorView(error: error)
            } else {
                LoadinScreen()
            }
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
                dataCapturingService: MockDataCapturingService(state: .stopped)
            ), loginViewModel: LoginViewModel()
        )
    }
}
#endif
