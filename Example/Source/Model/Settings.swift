/*
 * Copyright 2021 Cyface GmbH
 *
 * This file is part of the Cyface SDK for iOS.
 *
 * The Cyface SDK for iOS is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Cyface SDK for iOS is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Cyface SDK for iOS. If not, see <http://www.gnu.org/licenses/>.
 */
import Foundation

/**
 Access, write and react to changes within the apps settings.

 This class allows access to the applications settings, which can be adapted view the devices settings menu.
 Among these settings are the credentials to access a Cyface server as well as the URL to that server.
 There is also the information on whether data should be synchronized automatically or not.

 Additionally there are several hidden settings for managed information, like the last authenticated server and the last already accepted privacy policy.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 9.0.0
 */
class Settings: NSObject {
    // MARK: - Constants
    /// The settings key for the toggle to activate or deactivate automatic data syncrhonization.
    private static let syncToggleKey = "de.cyface.sync_toggle"
    /// The settings key for the setting storing the URL to the currently used synchronization server.
    private static let serverURLKey = "de.cyface.serverurl"
    /// The settings key for the setting storing the currently used username to authenticate with the server and to upload data.
    private static let usernameKey = "de.cyface.login"
    /// The settings key for the setting storing the currently used password to authenticate with the server and to upload data.
    private static let passwordKey = "de.cyface.password"
    /// The setting key for the setting storing the server the user is currently authenticated on. This is required to notice instances where the server URL and the authenticated server URL differ to ask for reauthentication.
    private static let authenticatedOnServerKey = "de.cyface.settings.loggedin"
    /// The setting key for the setting storing the highest privacy policy version that was accepted by the user. This is required to ask for acceptance on newer versions of the privacy policy.
    private static let highestAcceptedPrivacyPolicyKey = "de.cyface.settings.privacy_policy_version"
    /// The username of the guest user used to access the default server anonymously.
    static let guestUsername = CyfaceCreds.clientId
    /// The password used to access the default server anonymously.
    static let guestPassword = CyfaceCreds.clientSecret
    /// The default server address, which can be accessed using a guest login.
    static let defaultServerURL = "https://s2.cyface.de/api/v2"
    // MARK: - Properties
    /// Needs to be stored here, so we can avoid asking for credentials after an URL change to the same URL as before (if the user changed his/her mind for example or if the settings change was caused by a different setting).
    private var oldServerUrl: String?
    /// Objects interested in changes to the current Cyface server URL.
    private var serverUrlChangedListener: [ServerUrlChangedListener] = []

    /// The URL to the currently used synchronization server.
    var serverUrl: String? {
        get {
            UserDefaults.standard.string(forKey: Settings.serverURLKey)
        }

        set(value) {
            UserDefaults.standard.set(value, forKey: Settings.serverURLKey)
        }
    }

    /// The server the user is currently authenticated on. This is required to notice instances where the server URL and the authenticated server URL differ to ask for reauthentication.
    var authenticatedServerUrl: String? {
        get {
            UserDefaults.standard.string(forKey: Settings.authenticatedOnServerKey)
        }

        set(value) {
            UserDefaults.standard.set(value, forKey: Settings.authenticatedOnServerKey)
        }
    }

    /// The highest privacy policy version that was accepted by the user. This is required to ask for acceptance on newer versions of the privacy policy.
    var highestAcceptedPrivacyPolicy: Int {
        get {
            UserDefaults.standard.integer(forKey: Settings.highestAcceptedPrivacyPolicyKey)
        }

        set(value) {
            UserDefaults.standard.set(value, forKey: Settings.highestAcceptedPrivacyPolicyKey)
        }
    }

    /// The currently used username to authenticate with the server and to upload data.
    var username: String? {
        get {
            UserDefaults.standard.string(forKey: Settings.usernameKey)
        }

        set(value) {
            UserDefaults.standard.set(value, forKey: Settings.usernameKey)
        }
    }

    /// The setting storing the currently used password to authenticate with the server and to upload data.
    var password: String? {
        get {
            UserDefaults.standard.string(forKey: Settings.passwordKey)
        }

        set(value) {
            UserDefaults.standard.set(value, forKey: Settings.passwordKey)
        }
    }

    /// The toggle to activate or deactivate automatic data syncrhonization.
    var synchronizeData: Bool {
        get {
            UserDefaults.standard.bool(forKey: Settings.syncToggleKey)
        }

        set(value) {
            UserDefaults.standard.set(value, forKey: Settings.syncToggleKey)
        }
    }

    // MARK: - Initializers
    /// A no-argument initializer setting up the settings and starting surveillance of setting changes.
    override init() {
        super.init()
        let settingsUrl = Bundle.main.url(forResource: "Settings", withExtension: "bundle")!.appendingPathComponent("Root.plist")
        let settingsPlist = NSDictionary(contentsOf: settingsUrl)!
        guard let preferences = settingsPlist["PreferenceSpecifiers"] as? [NSDictionary] else {
            fatalError()
        }

        var defaultsToRegister = [String: Any]()

        for preference in preferences {
            guard let key = preference["Key"] as? String else {
                NSLog("Key not fount")
                continue
            }

            defaultsToRegister[key] = preference["DefaultValue"]
        }
        UserDefaults.standard.register(defaults: defaultsToRegister)
        oldServerUrl = serverUrl
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onUploadServerUrlChanged(notification:)),
                                               name: UserDefaults.didChangeNotification,
                                               object: nil)
    }

    // MARK: - Methods
    /**
     Method called on each change to a setting. It notifies listeners registerd as `serverUrlChangedListener` about changes to the server URL.

     - Parameter notification: A notification that contains the current settings for easy and fast access
     */
    @objc
    private func onUploadServerUrlChanged(notification: NSNotification) {
        guard (notification.object as? UserDefaults) != nil else {
            return
        }

        guard oldServerUrl != serverUrl else {
            return
        }

        guard let newServerUrl = serverUrl else {
            for serverUrlChangedListener in self.serverUrlChangedListener {
                serverUrlChangedListener.toInvalidUrl()
            }
            return
        }

        oldServerUrl = newServerUrl
        // If the server URL actually changed we need to re login or ask for a valid URL
        if newServerUrl.isEmpty {
            for serverUrlChangedListener in self.serverUrlChangedListener {
                serverUrlChangedListener.toInvalidUrl()
            }
        } else {
            // Display login view again
            for serverUrlChangedListener in self.serverUrlChangedListener {
                serverUrlChangedListener.toValidUrl()
            }
        }
    }

    /**
     Add the provided `ServerUrlChangedListener` to the objects that are notified each time the current server URL setting changes. Notifications are send out if the URL is changed from within the app as well as Apples settings app.

     - Parameter serverUrlChangedListener: The listener to add to the list of listeners
     */
    func add(serverUrlChangedListener listener: ServerUrlChangedListener) {
        serverUrlChangedListener.append(listener)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - ServerUrlChangedListener
/**
Protocol required by objects that want to be notified about changes to the server URL setting.

 Notifications are sent out on each change.
 So if an URL contains 10 letters, 10 notifications will be received, if that URL was added via the Apple settings app.
 This means, calls to `toValidUrl()` or `toInvalidUrl` should be idempotent or require very little performance from the system.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
protocol ServerUrlChangedListener {
    /**
     Called if the server URL is changed to a valid value.
     Checks currently only for the URL value to not be empty.
     Further checks might be added in the future.
     */
    func toValidUrl()

    /**
     Called if the server URL is changed to an invalid value.
     Invalid are empty `String` instances at the moment.
     */
    func toInvalidUrl()
}