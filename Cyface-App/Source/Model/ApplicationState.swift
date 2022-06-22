//
//  ApplicationState.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 19.06.22.
//

import Foundation

class ApplicationState: ObservableObject, ServerUrlChangedListener {
    let settings: Settings
    @Published var hasAcceptedCurrentPrivacyPolicy: Bool
    @Published var isLoggedIn: Bool
    @Published var hasValidServerURL: Bool

    init(settings: Settings) {
        self.hasAcceptedCurrentPrivacyPolicy = settings.highestAcceptedPrivacyPolicy >= PrivacyPolicy.currentPrivacyPolicyVersion
        if let authenticatedURL = settings.authenticatedServerUrl {
            hasValidServerURL = authenticatedURL == settings.serverUrl
        } else if let unwrappedURL = settings.serverUrl {
            do {
                if let url = URL(string: unwrappedURL) {
                    hasValidServerURL = try url.checkResourceIsReachable()
                } else {
                    hasValidServerURL = false
                }
            } catch {
                hasValidServerURL = false
            }
        } else {
            hasValidServerURL = false
        }

        self.isLoggedIn = hasValidServerURL || (settings.authenticatedServerUrl == settings.serverUrl)
        self.settings = settings
        self.settings.add(serverUrlChangedListener: self)
    }

    func acceptPrivacyPolicy() {
        settings.highestAcceptedPrivacyPolicy = PrivacyPolicy.currentPrivacyPolicyVersion
        hasAcceptedCurrentPrivacyPolicy = true
    }

    func toValidUrl() {
        self.isLoggedIn = false
        self.hasValidServerURL = true
    }

    func toInvalidUrl() {
        self.isLoggedIn = false
        self.hasValidServerURL = false
    }
}
