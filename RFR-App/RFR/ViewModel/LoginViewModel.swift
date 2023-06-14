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
        let decoder = JSONDecoder()
        guard let configurationFile = Bundle.main.url(forResource: "auth.conf", withExtension: "json") else {
            throw RFRError.missingAuthenticatorConfiguration
        }
        let configurationData = try Data(contentsOf: configurationFile)
        let authenticatorConfiguration = try decoder.decode(AuthenticatorConfiguration.self, from: configurationData)
        guard let issuer = URL(string: authenticatorConfiguration.issuer) else {
            throw RFRError.invalidUrl(url: authenticatorConfiguration.issuer)
        }
        self.authenticator = OAuthAuthenticator(
            issuer: issuer,
            clientId: authenticatorConfiguration.clientId,
            clientSecret: authenticatorConfiguration.clientSecret
        )
        
        self.isAuthenticated = false
        do {
            self.credentials = try Credentials.search(issuer: authenticatorConfiguration.issuer)
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
            onSuccess: { try credentials.save(issuer: authenticator.authenticationEndpoint.absoluteString) },
            onError: { self.error = ($0) }
        )
    }

    /*func onViewModelInitialized() async {
        await authenticate(onError: { error in
            switch error {
            case ServerConnectionError.authenticationNotSuccessful(let username):
                // Do nothing on an authenticationNotSuccessful
                os_log("Authentication failed for user %@. Showing login screen.", log: OSLog.authorization, type: .info, username)
            default:
                self.error = error
            }
        })
    }*/

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

struct AuthenticatorConfiguration: Codable {
    let issuer: String
    let clientId: String
    let clientSecret: String
}
