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

class Credentials: ObservableObject {
    @Published var username: String
    @Published var password: String

    init(username: String = "", password: String = "") {
        self.username = username
        self.password = password
    }

    func save() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrAccount as String: username,
            kSecAttrServer as String: RFRApp.authenticationEndpoint,
            kSecValueData as String: password.data(using: String.Encoding.utf8)!
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    static func search() throws -> Credentials{
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: RFRApp.authenticationEndpoint,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status != errSecItemNotFound else { throw KeychainError.noPassword }
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status)}

        guard let existingItem = item as? [String: Any],
              let passwordData = existingItem[kSecValueData as String] as? Data,
              let password = String(data: passwordData, encoding: String.Encoding.utf8),
              let account = existingItem[kSecAttrAccount as String] as? String
        else {
            throw KeychainError.unexpectedPasswordData
        }
        return Credentials(username: account, password: password)
    }
}

enum KeychainError: Error {
    case noPassword
    case unexpectedPasswordData
    case unhandledError(status: OSStatus)
}
