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
    @StateObject var privacyPolicy = PrivacyPolicy()
    @State private var loggedIn: Bool = false
    @State private var error: Error?
    let appDelegate: AppDelegate

    var body: some View {
        if viewModel.isInitialized,
            let dataStoreStack = viewModel.dataStoreStack {

            Group {
                if loggedIn {
                    MainView(
                        viewModel: viewModel,
                        syncViewModel: SynchronizationViewModel(
                            synchronizer: MockSynchronizer()
                        )
                    )
                } else if privacyPolicy.mostRecentWasAccepted {
                    OAuthLoginView(appDelegate: appDelegate, loggedIn: $loggedIn, error: $error)

                } else {
                    VStack {
                        WebView(url: privacyPolicy.url)
                        Button(action:  {
                            privacyPolicy.onAccepted()
                        }) {
                            Text("Akzeptieren")
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding([.leading, .trailing, .bottom])
                    .buttonStyle(.borderedProminent)
                }
            }

        /*} else {
            if let error = viewModel.error {
                ErrorView(error: error)
            } else {
                LoadinScreen()
            }*/
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
