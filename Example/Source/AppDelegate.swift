//
//  AppDelegate.swift
//  Cyface-Test
//
//  Created by Team Cyface on 06.11.17.
//  Copyright © 2017 Cyface GmbH. All rights reserved.
//

import UIKit
import DataCapturing
import CoreData

// TODO move url changing code to here and check that we are not in login view before presenting that view, but always update the server connections url.
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Constants
    static let syncToggleKey = "de.cyface.sync_toggle"
    static let serverURLKey = "de.cyface.serverurl"
    static let usernameKey = "de.cyface.login"
    static let passwordKey = "de.cyface.password"
    static let isAuthenticatedKey = "de.cyface.settings.loggedin"
    static let highestAcceptedPrivacyPolicyKey = "de.cyface.settings.privacy_policy_version"
    static let guestUsername = CyfaceCreds.clientId
    static let guestPassword = CyfaceCreds.clientSecret
    static let defaultServerURL = "https://s2.cyface.de/api/v2"
    static let mainStoryBoard = "Cyface-Main"
    static let privacyPolicyStoryBoard = "PrivacyPolicy"

    // MARK: - Properties
    var window: UIWindow?
    var coreDataStack: CoreDataManager?
    var serverConnection: ServerConnection?
    var authenticator: CredentialsAuthenticator?
    var oldServerUrl: String!

    // MARK: - UIApplicationDelegate
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        registerDefaultsFromSettingsBundle()
        oldServerUrl = UserDefaults.standard.string(forKey: AppDelegate.serverURLKey)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onUploadServerUrlChanged(notification:)),
                                               name: UserDefaults.didChangeNotification,
                                               object: nil)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                return
            }

            let coreDataStack = CoreDataManager()
            let bundle = Bundle(for: type(of: coreDataStack))
            coreDataStack.setup(bundle: bundle) {
                self.coreDataStack = coreDataStack

                self.serverConnection = self.createServerConnection()

                DispatchQueue.main.async {
                    self.presentMainUI()
                }
            }
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // MARK: - Methods
    // FIXME: This hopefully changes in a future version of iOS
    /// In the beginning the app needs to load default settings from the Settings.bundle. Only Apple knows why this is necessary and it seems like a pretty dirty hack, but the code does not work without this. This will hopefully be fixed in the future
    private func registerDefaultsFromSettingsBundle() {
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
    }

    private func presentMainUI() {
        self.window = UIWindow(frame: UIScreen.main.bounds)

        let storyboard = UIStoryboard(name: AppDelegate.mainStoryBoard, bundle: nil)
        let privacyPolicyStoryboard = UIStoryboard(name: AppDelegate.privacyPolicyStoryBoard, bundle: nil)
        let highestAcceptedPrivacyPolicyVersion = UserDefaults.standard.integer(forKey: AppDelegate.highestAcceptedPrivacyPolicyKey)

        if highestAcceptedPrivacyPolicyVersion == PrivacyPolicyViewController.currentPrivacyPolicyVersion {
            if UserDefaults.standard.bool(forKey: AppDelegate.isAuthenticatedKey) {
                window?.rootViewController = storyboard.instantiateViewController(withIdentifier: "CyfaceViewController")
            } else {
                window?.rootViewController = storyboard.instantiateInitialViewController()
            }
        } else {
            window?.rootViewController = privacyPolicyStoryboard.instantiateInitialViewController()
        }
        window?.makeKeyAndVisible()
    }

    private func createServerConnection() -> ServerConnection? {
        // TODO test what happens if we delete the server URL altogether.
        guard let serverURLString = UserDefaults.standard.string(forKey: AppDelegate.serverURLKey) else {
            fatalError("Missing server URL!")
        }

        guard let coreDataStack = coreDataStack else {
            fatalError()
        }

        let serverURL = URL(string: serverURLString)!

        let authenticator = CredentialsAuthenticator(authenticationEndpoint: serverURL)
        authenticator.username = UserDefaults.standard.string(forKey: AppDelegate.usernameKey)
        authenticator.password = UserDefaults.standard.string(forKey: AppDelegate.passwordKey)
        self.authenticator = authenticator
        return ServerConnection(apiURL: serverURL, authenticator: authenticator, onManager: coreDataStack)
    }

    @objc
    func onUploadServerUrlChanged(notification: NSNotification) {
        debugPrint("Changed setting")
        guard let newServerUrl = UserDefaults.standard.string(forKey: AppDelegate.serverURLKey) else {
            fatalError("No server URL available in settings!")
        }

        if oldServerUrl != newServerUrl {
            serverConnection?.apiURL = URL(string: newServerUrl)!
            authenticator?.authenticationEndpoint = URL(string: newServerUrl)!
            oldServerUrl = newServerUrl
            UserDefaults.standard.set(false, forKey: AppDelegate.isAuthenticatedKey)
            let storyBoard: UIStoryboard = UIStoryboard(name: AppDelegate.mainStoryBoard, bundle: nil)
            let loginViewController = storyBoard.instantiateViewController(withIdentifier: "LoginViewController")
            window?.rootViewController = loginViewController
            window?.makeKeyAndVisible()
        }
    }
}

extension UIViewController {
    var appDelegate: AppDelegate {
        guard let appDelegate = (UIApplication.shared.delegate as? AppDelegate) else {
            fatalError("Unable to load AppDelegate!")
        }
        return appDelegate
    }

    var authenticator: CredentialsAuthenticator {
        guard let authenticator = appDelegate.authenticator  else {
            fatalError("Unable to load Authenticator!")
        }
        return authenticator
    }

    var coreDataStack: CoreDataManager {
        guard let coreDataStack = appDelegate.coreDataStack  else {
            fatalError("Unable to load CoreDataStack!")
        }
        return coreDataStack
    }

    var serverConnection: ServerConnection {
        guard let serverConnection = appDelegate.serverConnection  else {
            fatalError("Unable to load ServerConnection!")
        }
        return serverConnection
    }
}
