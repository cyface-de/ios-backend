//
//  AppDelegate.swift
//  RFR
//
//  Created by Klemens Muthmann on 21.08.23.
//

import AppAuthCore
import UIKit
import OSLog

class AppDelegate: NSObject, UIApplicationDelegate {
    var currentAuthorizationFlow: OIDExternalUserAgentSession?

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        os_log("Opened App via callback from @%.", log: OSLog.system, type: .info, url.absoluteString)

        if let authorizationFlow = self.currentAuthorizationFlow, authorizationFlow.resumeExternalUserAgentFlow(with: url) {
            self.currentAuthorizationFlow = nil
            return true
        }

        return false
    }
}
