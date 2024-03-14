//
//  AppDelegate.swift
//  RFR
//
//  Created by Klemens Muthmann on 26.02.24.
//

import UIKit
import DataCapturing

/**
 Handles Application level UIKit events. This is still necessary for use cases that are not supported by SwiftUI yet or that need to be portable to older versions.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
class AppDelegate: NSObject, UIApplicationDelegate {
    /// A delegate called, when this app is created to repeat or start upload of a background `URLSession`.
    var delegate: BackgroundURLSessionEventDelegate?

    /// Called after waking up for handling a background `URLSession`.
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        delegate?.received(application, handleEventsForBackgroundURLSession: identifier, completionHandler: completionHandler)
    }
}
