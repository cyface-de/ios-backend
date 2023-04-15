//
//  LoginViewModel.swift
//  RFR
//
//  Created by Klemens Muthmann on 04.04.23.
//

import Foundation
import DataCapturing

class LoginViewModel: ObservableObject {
    @Published var username = ""
    @Published var password = ""
    @Published var showError = false
    var error: Error?
    var authenticator: CredentialsAuthenticator?

    init() {
        guard let url = URL(string: RFRApp.authenticationEndpoint) else {
            handleError(RFRError.invalidUrl(url: RFRApp.authenticationEndpoint))
            return
        }
        self.authenticator = CyfaceAuthenticator(authenticationEndpoint: url)
    }

    init(username: String, password: String, showError: Bool, error: Error?, authenticator: CredentialsAuthenticator) {
        self.username = username
        self.password = password
        self.showError = showError
        self.error = error
        self.authenticator = authenticator
    }

    func authenticate() async -> String? {
        guard var authenticator = self.authenticator else {
            handleError(RFRError.missingAuthenticator)
            return nil
        }

        authenticator.username = username
        authenticator.password = password

        do {
            return try await authenticator.authenticate()
        } catch {
            handleError(error)
            return nil
        }
    }

    private func handleError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            self.error = error
            self.showError = true
        }
    }
}
