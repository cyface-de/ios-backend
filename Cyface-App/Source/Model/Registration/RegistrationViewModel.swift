//
//  RegistrationViewModel.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 20.07.22.
//

import Foundation

class RegistrationViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = "" {
        didSet {
            passwordsAreEqualAndNotEmpty = !password.isEmpty && !repeatedPassword.isEmpty && repeatedPassword==password
        }
    }
    @Published var repeatedPassword: String = "" {
        didSet {
            passwordsAreEqualAndNotEmpty = !password.isEmpty && !repeatedPassword.isEmpty && repeatedPassword==password
        }
    }
    @Published var passwordsAreEqualAndNotEmpty = false
    @Published var challengeToken: String
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var registrationSuccessful = false

    init(validationToken: String) {
        self.challengeToken = validationToken
    }

    func register(url: URL) async {

        let requestURL = url.appendingPathComponent("user")
        let registrationRequest = RegistrationRequest(url: requestURL)

        do {
            try await registrationRequest.request(username: username, password: password, validationToken: challengeToken)
            self.registrationSuccessful = true
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.showError = true
                self?.errorMessage = error.localizedDescription
            }
        }
    }
}
