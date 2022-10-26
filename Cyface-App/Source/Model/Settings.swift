/*
 * Copyright 2021-2022 Cyface GmbH
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
import OSLog

/**
 Access, write and react to changes within the apps settings.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 1.0.0
 */
protocol Settings: NSObject {
    /// The URL to the currently used synchronization server.
    var serverUrl: String? { get set }

    /// The URL to use for the registration of user accounts.
    var registrationURL: String? { get set }

    /// The server the user is currently authenticated on. This is required to notice instances where the server URL and the authenticated server URL differ to ask for reauthentication.
    var authenticatedServerUrl: String? { get set }

    /// The highest privacy policy version that was accepted by the user. This is required to ask for acceptance on newer versions of the privacy policy.
    var highestAcceptedPrivacyPolicy: Int { get set }

    /// The currently used username to authenticate with the server and to upload data.
    var username: String? { get set }

    /// The setting storing the currently used password to authenticate with the server and to upload data.
    var password: String? { get set }

    /// The toggle to activate or deactivate automatic data syncrhonization.
    var synchronizeData: Bool { get set }

    /**
     Add the provided `ServerUrlChangedListener` to the objects that are notified each time the current server URL setting changes. Notifications are send out if the URL is changed from within the app as well as Apples settings app.

     - Parameter serverUrlChangedListener: The listener to add to the list of listeners
     */
    func add(serverUrlChangedListener listener: ServerUrlChangedListener)

    /**
     Add the provided `UploadToggleChangedListener` to the objects that are notified each time the user changes whether the app should upload data or not.
     */
    func add(uploadToggleChangedListener listener: UploadToggleChangedListener)
}

/**
 An implementation of the ``Settings`` protocol using an actual plist property file to store the setting values.

 This class allows access to the applications settings, which can be adapted view the devices settings menu.
 Among these settings are the credentials to access a Cyface server as well as the URL to that server.
 There is also the information on whether data should be synchronized automatically or not.

 Additionally there are several hidden settings for managed information, like the last authenticated server and the last already accepted privacy policy.

 - author: Klemens Muthmann
 - version: 1.0.0
 - since: 1.0.0
 */
class PropertySettings: NSObject, Settings {
    // MARK: - Constants
    /// The settings key for the toggle to activate or deactivate automatic data syncrhonization.
    private static let syncToggleKey = "de.cyface.sync_toggle"
    /// The settings key for the setting storing the URL to the currently used synchronization server.
    private static let serverURLKey = "de.cyface.serverurl"
    /// The settings key for the setting storing the URL to the currently used registration server.
    private static let registrationURLKey = "de.cyface.registrationurl"
    /// The settings key for the setting storing the currently used username to authenticate with the server and to upload data.
    private static let usernameKey = "de.cyface.login"
    /// The settings key for the setting storing the currently used password to authenticate with the server and to upload data.
    private static let passwordKey = "de.cyface.password"
    /// The setting key for the setting storing the server the user is currently authenticated on. This is required to notice instances where the server URL and the authenticated server URL differ to ask for reauthentication.
    private static let authenticatedOnServerKey = "de.cyface.settings.loggedin"
    /// The setting key for the setting storing the highest privacy policy version that was accepted by the user. This is required to ask for acceptance on newer versions of the privacy policy.
    private static let highestAcceptedPrivacyPolicyKey = "de.cyface.settings.privacy_policy_version"
    /// The default server address, which can be accessed using a guest login.
    static let defaultServerURL = "https://s2.cyface.de/api/v2"

    // MARK: - Properties
    /// Needs to be stored here, so we can avoid asking for credentials after an URL change to the same URL as before (if the user changed his/her mind for example or if the settings change was caused by a different setting).
    private var oldServerUrl: String?
    /// Wether to synchronize data before the last settings change. This needs to be stored here, so we can identify if a settings change happened due to the synchronization toggle changing.
    private var oldSynchronizeData: Bool?
    /// Objects interested in changes to the current Cyface server URL.
    private var serverUrlChangedListener: [ServerUrlChangedListener] = []
    /// A list of listeners who are informed every time the synchronization toggle was switched.
    private var synchronizationToggleChangedListener: [UploadToggleChangedListener] = []

    /// The URL to the currently used synchronization server.
    var serverUrl: String? {
        get {
            UserDefaults.standard.string(forKey: PropertySettings.serverURLKey)
        }

        set(value) {
            UserDefaults.standard.set(value, forKey: PropertySettings.serverURLKey)
        }
    }

    /// The URL used to address the registration server.
    var registrationURL: String? {
        get {
            UserDefaults.standard.string(forKey: PropertySettings.registrationURLKey)
        }

        set(value) {
            UserDefaults.standard.set(value, forKey: PropertySettings.registrationURLKey)
        }
    }

    /// The server the user is currently authenticated on. This is required to notice instances where the server URL and the authenticated server URL differ to ask for reauthentication.
    var authenticatedServerUrl: String? {
        get {
            UserDefaults.standard.string(forKey: PropertySettings.authenticatedOnServerKey)
        }

        set(value) {
            UserDefaults.standard.set(value, forKey: PropertySettings.authenticatedOnServerKey)
        }
    }

    /// The highest privacy policy version that was accepted by the user. This is required to ask for acceptance on newer versions of the privacy policy.
    var highestAcceptedPrivacyPolicy: Int {
        get {
            UserDefaults.standard.integer(forKey: PropertySettings.highestAcceptedPrivacyPolicyKey)
        }

        set(value) {
            UserDefaults.standard.set(value, forKey: PropertySettings.highestAcceptedPrivacyPolicyKey)
        }
    }

    /// The currently used username to authenticate with the server and to upload data.
    var username: String? {
        get {
            UserDefaults.standard.string(forKey: PropertySettings.usernameKey)
        }

        set(value) {
            UserDefaults.standard.set(value, forKey: PropertySettings.usernameKey)
        }
    }

    /// The setting storing the currently used password to authenticate with the server and to upload data.
    var password: String? {
        get {
            UserDefaults.standard.string(forKey: PropertySettings.passwordKey)
        }

        set(value) {
            UserDefaults.standard.set(value, forKey: PropertySettings.passwordKey)
        }
    }

    /// The toggle to activate or deactivate automatic data syncrhonization.
    var synchronizeData: Bool {
        get {
            UserDefaults.standard.bool(forKey: PropertySettings.syncToggleKey)
        }

        set(value) {
            UserDefaults.standard.set(value, forKey: PropertySettings.syncToggleKey)
        }
    }

    // MARK: - Initializers
    /// A no-argument initializer setting up the settings and starting surveillance of setting changes.
    override init() {
        super.init()
        guard let settingsBundle = Bundle.main.url(forResource: "Settings", withExtension: "bundle") else {
            fatalError("Unable to load Settings bundle from main bundle!")
        }
        let settingsUrl = settingsBundle.appendingPathComponent("Root.plist")
        let settingsPlist = NSDictionary(contentsOf: settingsUrl)!
        guard let preferences = settingsPlist["PreferenceSpecifiers"] as? [NSDictionary] else {
            fatalError()
        }

        var defaultsToRegister = [String: Any]()

        for preference in preferences {
            guard let key = preference["Key"] as? String else {
                NSLog("Key not found")
                continue
            }

            defaultsToRegister[key] = preference["DefaultValue"]
        }
        UserDefaults.standard.register(defaults: defaultsToRegister)
        oldServerUrl = serverUrl
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onSettingsChanged(notification:)),
                                               name: UserDefaults.didChangeNotification,
                                               object: nil)
    }

    // MARK: - Methods
    /**
     Method called on each change to a setting. It notifies listeners registerd as `serverUrlChangedListener` about changes to the server URL.

     - Parameter notification: A notification that contains the current settings for easy and fast access
     */
    @objc
    private func onSettingsChanged(notification: NSNotification) {
        os_log("System settings changed!")
        guard (notification.object as? UserDefaults) != nil else {
            return
        }

        if oldServerUrl != serverUrl {
            onUploadServerUrlChanged()
        }
        if oldSynchronizeData != synchronizeData {
            onSynchronizeDataToggleChanged()
        }
    }

    /**
     Called if the user changed the upload server URL via the application system settings.
     */
    private func onUploadServerUrlChanged() {
        guard let newServerURL = serverUrl else {
            for serverUrlChangedListener in self.serverUrlChangedListener {
                serverUrlChangedListener.to(invalidURL: serverUrl)
            }
            return
        }

        oldServerUrl = newServerURL
        // If the server URL actually changed we need to re login or ask for a valid URL
        guard !newServerURL.isEmpty else {
            for serverUrlChangedListener in self.serverUrlChangedListener {
                serverUrlChangedListener.to(invalidURL: newServerURL)
            }
            return
        }

        guard let parsedURL = URL(string: newServerURL) else {
            for serverUrlChangedListener in self.serverUrlChangedListener {
                serverUrlChangedListener.to(invalidURL: newServerURL)
            }
            return
        }

        // Display login view again
        for serverUrlChangedListener in self.serverUrlChangedListener {
            serverUrlChangedListener.to(validURL: parsedURL)
        }
    }

    /// Called if the user changed the synchronization toggle via the application system settings.
    private func onSynchronizeDataToggleChanged() {
        for listener in synchronizationToggleChangedListener {
            listener.to(upload: synchronizeData)
        }
    }

    /// Adds the provided `listener` to be informed about server URL changes via the system settings application.
    func add(serverUrlChangedListener listener: ServerUrlChangedListener) {
        serverUrlChangedListener.append(listener)
    }

    /// Adds the provided `listener` to be informed about changes to the upload toggle status.
    func add(uploadToggleChangedListener listener: UploadToggleChangedListener) {
        synchronizationToggleChangedListener.append(listener)
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
 - Since:
 */
protocol ServerUrlChangedListener {
    /**
     Called if the server URL is changed to a valid value.
     Checks currently only for the URL value to not be empty.
     Further checks might be added in the future.
     */
    func to(validURL: URL)

    /**
     Called if the server URL is changed to an invalid value.
     Invalid are empty `String` instances at the moment.
     */
    func to(invalidURL: String?)
}

// MARK: - UploadToggleChangedListener
/**
 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 4.0.0
 */
protocol UploadToggleChangedListener {
    /// Called with the value the upload toggle was changed to.
    func to(upload: Bool)
}

// MARK: - PreviewSettings
class PreviewSettings: NSObject, Settings {
    var serverUrl: String? = "http://localhost:8080/api/v3/"

    var registrationURL: String? = "http://localhost:8080/registration"

    var authenticatedServerUrl: String? = "http://localhost:8080/api/v3/"

    var highestAcceptedPrivacyPolicy: Int = 1

    var username: String? = ""

    var password: String? = ""

    var synchronizeData: Bool = false

    func add(serverUrlChangedListener listener: ServerUrlChangedListener) {
        // Nothing to do here.
    }

    func add(uploadToggleChangedListener listener: UploadToggleChangedListener) {
        // Nothing to do here.
    }
}
