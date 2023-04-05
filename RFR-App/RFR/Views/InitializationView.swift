//
//  InitializationView.swift
//  RFR
//
//  Created by Klemens Muthmann on 15.03.23.
//

import SwiftUI

struct InitializationView: View {
    @StateObject var viewModel: DataCapturingViewModel
    @State private var isAuthenticated = false

    var body: some View {
        if(viewModel.isInitialized) {

            if isAuthenticated {
                MainView(
                    isAuthenticated: $isAuthenticated,
                    viewModel: viewModel
                )
            } else {
                LoginView(
                    viewModel: LoginViewModel(), isAuthenticated: $isAuthenticated
                )
            }

        } else {
            LoadinScreen()
                .alert(isPresented: $viewModel.showError) {
                    Alert(
                        title: Text("Error"),
                        message: Text(viewModel.error?.localizedDescription ?? "")
                    )
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
                username: "",
                password: "",
                error: nil,
                dataCapturingService: MockDataCapturingService(state: .stopped)
            )
        )
    }
}
#endif
