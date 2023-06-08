//
//  LoginViewModel.swift
//  RFR
//
//  Created by Klemens Muthmann on 04.04.23.
//

import Foundation
import DataCapturing
import OSLog

@MainActor
class LoginViewModel: ObservableObject {
    var credentials: Credentials
    @Published var error: Error?
    @Published var authenticator: CredentialsAuthenticator
    @Published var isAuthenticated: Bool

    init() async throws {
        guard let url = URL(string: RFRApp.authenticationEndpoint) else {
            throw RFRError.invalidUrl(url: RFRApp.authenticationEndpoint)
        }
        self.authenticator = CyfaceAuthenticator(authenticationEndpoint: url)
        self.isAuthenticated = false
        do {
            self.credentials = try Credentials.search()
            await authenticate()
        } catch KeychainError.noPassword {
            self.credentials = Credentials()
        }
    }

    init(credentials: Credentials = Credentials(), error: Error?, authenticator: CredentialsAuthenticator) {
        self.credentials = credentials
        self.error = error
        self.authenticator = authenticator
        self.isAuthenticated = false
    }

    func onLoginButtonClicked() async {
        await authenticate(
            onSuccess: { try credentials.save() },
            onError: { self.error = ($0) }
        )
    }

    func onViewModelInitialized() async {
        await authenticate(onError: { error in
            switch error {
            case ServerConnectionError.authenticationNotSuccessful(let username):
                // Do nothing on an authenticationNotSuccessful
                os_log("Authentication failed for user %@. Showing login screen.", log: OSLog.authorization, type: .info, username)
            default:
                self.error = error
            }
        })
    }

    private func authenticate(onSuccess: () throws -> () = {}, onError: (Error) -> () = { _ in }) async {
        authenticator.username = credentials.username
        authenticator.password = credentials.password

        do {
            _ = try await authenticator.authenticate()
            try onSuccess()
            self.isAuthenticated = true
        } catch {
            onError(error)
        }
    }
}

