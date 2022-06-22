/*
 * Copyright 2017 - 2022 Cyface GmbH
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

import UIKit
import DataCapturing
import CoreData

/**
 This is the entry point of the Cyface iOS app.

 One object of this class is created by the iOS system to start the Cyface iOS app.
 This object manages all objects of which only one instance is required or allowed and forwards them to the appropriate view controllers.
 It also starts the first `UIViewController`, initializes the database layer and connects to a Cyface data server.

 - Author: Klemens Muthmann
 - Version: 2.0.1
 - Since: 1.0.0
 */
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, ServerUrlChangedListener {

    // MARK: - Constants
    /// The name of the main storyboard file used by the Cyface iOS app
    static let mainStoryBoard = "Cyface-Main"

    // MARK: - Properties
    /// The application window, showing all the views.
    var window: UIWindow?
    /// The database access layer using iOS CoreData framework
    var coreDataStack: CoreDataManager?
    /// An authenticator authenticating users to login to the app and upload data to a Cyface collector service if valid.
    var authenticator: CredentialsAuthenticator?
    /// The persistent application settings. These includes hidden settings as well as those that can be customized using the systems settings app.
    let settings = Settings()
    /// The most recent version of the privacy policy
    let currentPrivacyPolicyVersion = 2

    // MARK: - Methods
    /// A method that decides which view is the first to show to the user.
    func presentMainUI() {
        // newest privacy policy not accepted, so we need to show it and ask for acceptance
        guard settings.highestAcceptedPrivacyPolicy == currentPrivacyPolicyVersion else {
            showAcceptPrivacyPolicyDialog(currentPrivacyPolicyVersion)
            return
        }

        // No Server provided in the settings so we ask for one.
        guard let currentServerInSettings = settings.serverUrl, !currentServerInSettings.isEmpty else {
            // show some dialog telling the user to enter the server url.
            showAskForServerDialog()
            return
        }

        guard let serverURL = URL(string: currentServerInSettings) else {
            showAskForServerDialog()
            return
        }

        let authenticator = CredentialsAuthenticator(authenticationEndpoint: serverURL)
        authenticator.username = settings.username
        authenticator.password = settings.password
        self.authenticator = authenticator

        // Authenticated server is the one from the settings so we start directly without login, otherwise login screen is shown.
        if settings.authenticatedServerUrl == currentServerInSettings {
            showMeasurementDialog()
        } else {
            showLoginDialog()
        }
    }

    /// Shows a dialog to the user asking for a valid server address to a Cyface collector service.
    private func showAskForServerDialog() {
        guard !isTypeOf(controller: window?.rootViewController, ofType: AskForServerViewController.self) else {
            return
        }

        window?.rootViewController=AskForServerViewController(AskForServerViewModel(settings))
        window?.makeKeyAndVisible()
    }

    /// Shows a dialog to the user asking to accept the Cyface privacy policy.
    private func showAcceptPrivacyPolicyDialog(_ currentPrivacyPolicyVersion: Int) {
        guard !isTypeOf(controller: window?.rootViewController, ofType: PrivacyPolicyViewController.self) else {
            return
        }

        window?.rootViewController = PrivacyPolicyViewController(PrivacyPolicyViewModel(settings, currentPrivacyPolicyVersion))
        window?.makeKeyAndVisible()
    }

    /// Shows a login dialog where the user can enter credentials to login to a Cyface collector service.
    private func showLoginDialog() {
        guard !isTypeOf(controller: window?.rootViewController, ofType: LoginViewController.self) else {
            return
        }

        let storyboard = UIStoryboard(name: AppDelegate.mainStoryBoard, bundle: nil)
        guard let loginViewController = storyboard.instantiateInitialViewController() as? LoginViewController else {
            fatalError("Unable to cast main storyboard initial view controller to a LoginViewController!")
        }
        // TODO: This late dependency injection is not necessary if using a proper programmatical MVVM.
        // Refactor the LoginViewController to follow that model!
        loginViewController.model = settings
        window?.rootViewController = loginViewController
        window?.makeKeyAndVisible()
    }

    /// Shows the main dialog, with controls to start, stop, pause and resume data capturing as well as an overview of the measurements available.
    private func showMeasurementDialog() {
        guard !isTypeOf(controller: window?.rootViewController, ofType: ViewController.self) else {
            return
        }

        let storyboard = UIStoryboard(name: AppDelegate.mainStoryBoard, bundle: nil)
        let instantiatedViewControler = storyboard.instantiateViewController(withIdentifier: "CyfaceViewController")
        guard let mainNavigationViewController = instantiatedViewControler as? UINavigationController else {
            fatalError("Wrong type for ViewController to show as main view controller. Must be of type ViewController")
        }

        guard let mainViewController = mainNavigationViewController.topViewController as? ViewController else {
            fatalError()
        }

        mainViewController.settings = settings
        window?.rootViewController = mainNavigationViewController
        window?.makeKeyAndVisible()
    }

    /// Checks if a ViewController is already displayed on screen to avoid calling the same one over and over again.
    private func isTypeOf(controller: UIViewController?, ofType controllerType: AnyClass) -> Bool {
        guard let controller = controller else {
            return false
        }

        if controller.isKind(of: UINavigationController.self) {
            guard let navigationController = window?.rootViewController as? UINavigationController else {
                fatalError()
            }

            guard let topViewController = navigationController.topViewController else {
                return false
            }

            return topViewController.isKind(of: controllerType)
        } else {
            return controller.isKind(of: controllerType)
        }
    }

    // MARK: - UIApplicationDelegate
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                return
            }

            self.settings.add(serverUrlChangedListener: self)
            do {
                let coreDataStack = try CoreDataManager()
                let bundle = Bundle(for: type(of: coreDataStack))
                try coreDataStack.setup(bundle: bundle) { [weak self] (error) in
                    if let error = error {
                        fatalError("Unable to setup CoreData stack due to: \(error)")
                    }
                    guard let self = self else {
                        return
                    }
                    self.coreDataStack = coreDataStack

                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else {
                            return
                        }

                        self.window = UIWindow(frame: UIScreen.main.bounds)
                        self.presentMainUI()
                    }
                }
            } catch {
                fatalError("Unable to setup CoreData stack due to: \(error)")
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

    // MARK: - ServerUrlChangedListener
    func toValidUrl() {
        presentMainUI()
    }

    func toInvalidUrl() {
        showAskForServerDialog()
    }
}

// MARK: - UIViewController
extension UIViewController {
    /// Provides the applications appDelegate to all the views. This must only be called on the main thread.
    var appDelegate: AppDelegate {
        guard let appDelegate = (UIApplication.shared.delegate as? AppDelegate) else {
            fatalError("Unable to load AppDelegate!")
        }
        return appDelegate
    }

    /// Provides the applications authenticator to all the views. This must only be called on the main thread.
    var authenticator: CredentialsAuthenticator {
        guard let authenticator = appDelegate.authenticator  else {
            fatalError("Unable to load Authenticator!")
        }
        return authenticator
    }

    /// Provides the applications CoreData stack to all the views. This must only be called on the main thread.
    var coreDataStack: CoreDataManager {
        guard let coreDataStack = appDelegate.coreDataStack  else {
            fatalError("Unable to load CoreDataStack!")
        }
        return coreDataStack
    }
}
