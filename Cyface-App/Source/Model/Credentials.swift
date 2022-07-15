//
//  Credentials.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 28.03.22.
//

import Foundation
import DataCapturing
import os.log

class Credentials: ObservableObject {
    @Published var username: String {
        didSet {
            settings.username = username
        }
    }
    @Published var password: String {
        didSet {
            settings.password = password
        }
    }
    @Published var authenticator: CredentialsAuthenticator?

    let settings: Settings
    let log = OSLog(subsystem: "Credentials", category: "de.cyface")

    init(settings: Settings) {
        self.settings = settings
        self.username = settings.username ?? ""
        self.password = settings.password ?? ""

        if let authenticatedServerURL = settings.authenticatedServerUrl  {
            if authenticatedServerURL == settings.serverUrl {
                do {
                    self.authenticator = try createAuthenticator()
                } catch {
                    os_log(.error, log: log, "Unable to create Authenticator for authenticated user %{PUBLIC}@ on URL %{PUBLIC}@", username, authenticatedServerURL)
                }
            }
        }
    }

    func login(onSuccess: @escaping ()->(), onFailure: @escaping (Error) -> Void) throws {
        let authenticator = try createAuthenticator()
        authenticator.authenticate(onSuccess: { [weak self] _ in
            self?.settings.authenticatedServerUrl = authenticator.authenticationEndpoint.absoluteString
            self?.authenticator = authenticator
            onSuccess()
        }, onFailure: onFailure)
    }

    private func createAuthenticator() throws -> CredentialsAuthenticator {
        guard let url = settings.serverUrl else {
            throw ViewError.noServerURL
        }

        guard let parsedURL = URL(string: url) else {
            throw ViewError.serverURLUnparseable(value: url)
        }

        let authenticator = CyfaceAuthenticator(authenticationEndpoint: parsedURL)
        authenticator.username = username
        authenticator.password = password

        return authenticator
    }
}
