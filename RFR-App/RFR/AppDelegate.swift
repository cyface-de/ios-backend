//
//  AppDelegate.swift
//  RFR
//
//  Created by Klemens Muthmann on 21.08.23.
//

import Foundation
import AppAuthCore
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    var currentAuthorizationFlow: OIDExternalUserAgentSession?

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if let authorizationFlow = self.currentAuthorizationFlow, authorizationFlow.resumeExternalUserAgentFlow(with: url) {
            self.currentAuthorizationFlow = nil
            return true
        }

        return false
    }
}
