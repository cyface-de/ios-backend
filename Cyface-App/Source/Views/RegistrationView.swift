//
//  RegistrationView.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 18.07.22.
//

import SwiftUI
import WebKit

/**
 A view showing the registration page on the Cyface Website

 - author: Klemens Muthmann
 - version: 1.0.0
 */
struct RegistrationView: UIViewControllerRepresentable {

    /*@ObservedObject var model: RegistrationViewModel
    let registrationURL: URL

    init(serverAddress: String?, model: RegistrationViewModel) {
        self.model = model
        guard let serverAddress = serverAddress else {
            fatalError()
        }

        guard let serverURL = URL(string: serverAddress) else {
            fatalError()
        }

        self.registrationURL = serverURL
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeUIViewController(context: Context) -> RegistrationNavigationDelegate {
        let webViewController = RegistrationNavigationDelegate(registrationURL: registrationURL, coordinator: context.coordinator)
        webViewController.loadUrl(registrationURL.appendingPathComponent("registration"))

        return webViewController
    }

    func updateUIViewController(_ uiView: RegistrationNavigationDelegate, context: UIViewControllerRepresentableContext<RegistrationView>) {
    }

    func onRegistrationFinished() {
        model.onRegistrationFinished()
    }*/
}
