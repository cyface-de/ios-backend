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
    @ObservedObject var loginViewModel: LoginViewModel

    var body: some View {
        if viewModel.isInitialized,
            let apiUrl = URL(string: RFRApp.uploadEndpoint),
            let dataStoreStack = viewModel.dataStoreStack {

            Group {
                if loginViewModel.isAuthenticated {
                    MainView(
                        isAuthenticated: $loginViewModel.isAuthenticated,
                        viewModel: viewModel,
                        syncViewModel: SynchronizationViewModel(
                            synchronizer: CyfaceSynchronizer(
                                apiURL: apiUrl,
                                dataStoreStack: dataStoreStack,
                                cleaner: AccelerationPointRemovalCleaner(),
                                authenticator: loginViewModel.authenticator
                            )
                        )
                    )
                } else {
                    LoginView(
                        viewModel: loginViewModel
                    )
                }
            }.onAppear {
                Task {
                    await loginViewModel.onViewModelInitialized()
                }
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
                dataStoreStack: MockDataStoreStack()
            ),
            loginViewModel: LoginViewModel(
                credentials: Credentials(),
                error: nil,
                authenticator: MockAuthenticator()
            )
        )
    }
}
#endif
