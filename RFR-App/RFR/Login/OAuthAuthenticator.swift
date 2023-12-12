/*
 * Copyright 2023 Cyface GmbH
 *
 * This file is part of the Ready for Robots App.
 *
 * The Ready for Robots App is free software: you can redistribute it and/or modify
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
import AppAuth
import DataCapturing
import OSLog

/**
 An ``DataCapturing.Authenticator`` implementation to realize an OAuth Auth flow.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
class OAuthAuthenticator {
    // MARK: - Static Properties
    /**
     The key used to identify the stored authentication state within the system shared preferences.
     */
    private static let appAuthStateKey = "de.cyface.authstate"

    // MARK: - Properties
    var callbackController: UIViewController? = nil
    private var authState: OIDAuthState? {
        didSet {
            saveState(authState, OAuthAuthenticator.appAuthStateKey)
        }
    }
    public let issuer: URL
    private let redirectUri: URL
    private let apiEndpoint: URL
    private let clientId: String
    private var currentAuthorizationFlow: OIDExternalUserAgentSession?
    private var config: OIDServiceConfiguration?
    private var idToken: String?

    // MARK: - Initializers
    /// - Parameter apiEndpoint: The endpoint running the Cyface API containing user self management.
    init(issuer: URL, redirectUri: URL, apiEndpoint: URL, clientId: String) {
        self.issuer = issuer
        self.redirectUri = redirectUri
        self.clientId = clientId
        self.apiEndpoint = apiEndpoint
        self.authState = loadState(OAuthAuthenticator.appAuthStateKey)
    }

    // MARK: - Private Methods
    private func serviceDiscovery() async throws -> OIDServiceConfiguration {
        os_log("Authentication: Discovering Settings", log: OSLog.authorization, type: .debug)
        if let config = self.config {
            return config
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) { configuration, error in
                    if let config = configuration {
                        os_log("Authentication: Settings discovered!", log: OSLog.authorization, type: .debug)
                        continuation.resume(returning: config)
                    } else {
                        continuation.resume(
                            throwing: OAuthAuthenticatorError.discoveryFailed(cause: error?.localizedDescription ?? "unkown error")
                        )
                    }
                }
            }
        }
    }

    private func doAuth(presenting callbackWindow: UIViewController) async throws {
        os_log("Authentication: Doing Authentication", log: OSLog.authorization, type: .debug)
        let clientId = clientId
        let redirectUri = redirectUri
        let config = try await serviceDiscovery()

        try await withUnsafeThrowingContinuation { continuation in
            // Build Authentication Request
            let request = OIDAuthorizationRequest(
                configuration: config,
                clientId: clientId,
                clientSecret: nil,
                scopes: [OIDScopeOpenID, OIDScopeProfile],
                redirectURL: redirectUri,
                responseType: OIDResponseTypeCode,
                additionalParameters: nil
            )
            DispatchQueue.main.async {
                os_log("Authentication: Authorization Endpoint: %@", log: OSLog.authorization, type: .debug, config.authorizationEndpoint.absoluteString)
                let currentAuthorizationFlow = OIDAuthState.authState(
                    byPresenting: request,
                    presenting: callbackWindow
                ) { authState, error in
                    os_log("Authentication: Received authentication response: %@", log: OSLog.authorization, type: .debug, authState ?? "nil")
                    if let authState = authState {
                        self.idToken = authState.lastTokenResponse?.idToken
                        self.authState = authState
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: OAuthAuthenticatorError.missingAuthState(cause: error))
                    }
                }
                self.currentAuthorizationFlow = currentAuthorizationFlow
            }
        }
    }

    func rootViewController() -> UIViewController {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene!.keyWindow!.rootViewController!
    }

    // TODO: Store state in keychain
    /// Store the authentication state between application restarts.
    private func saveState(_ authState: OIDAuthState?, _ appAuthStateKey: String) {
        os_log("Authentication: Saving the State.", log: OSLog.authorization, type: .debug)
        if let authState = authState {
            let archivedAuthState = NSKeyedArchiver.archivedData(withRootObject: authState)
            UserDefaults.standard.set(archivedAuthState, forKey: appAuthStateKey)
        } else {
            UserDefaults.standard.removeObject(forKey: appAuthStateKey)
        }
        UserDefaults.standard.synchronize()
    }

    /// Load the authentication state after an application restart.
    private func loadState(_ appAuthStateKey: String) -> OIDAuthState? {
        os_log("Authentication: Loading State.", log: OSLog.authorization, type: .debug)
        if let authState = self.authState {
            return authState
        } else if let archivedAuthState = UserDefaults.standard.object(forKey: appAuthStateKey) as? Data {
            if let authState = NSKeyedUnarchiver.unarchiveObject(with: archivedAuthState) as? OIDAuthState {
                return authState
            }
        }
        return nil
    }

    // MARK: - Internal Data Structures
    struct JWTToken {
        private static let jsonDecoder = JSONDecoder()
        let header: Substring
        let payload: Substring
        let signature: Substring
        let token: String
        let decoded: Decoded

        init(from token: String) throws {
            let splitToken = token.split(separator: ".")

            guard splitToken.count == 3 else {
                throw OAuthAuthenticatorError.invalidToken
            }
            self.header = splitToken[0]
            self.payload = splitToken[1]
            self.signature = splitToken[2]
            self.token = token

            var base64String = String(self.payload)

            // For explanation see: https://stackoverflow.com/questions/29152706/decoding-json-web-tokens-in-swift
            if base64String.count % 4 != 0 {
                let padlen = 4 - base64String.count % 4
                base64String.append(contentsOf: repeatElement("=", count: padlen))
            }

            if let data = Data(base64Encoded: base64String) {
                self.decoded = try JWTToken.jsonDecoder.decode(Decoded.self, from: data)
            } else {
                throw OAuthAuthenticatorError.invalidToken
            }
        }

        func asString() -> String {
            return token
        }

        struct Decoded: Decodable {
            let sub: UUID
        }
    }
}

// MARK: - Implementation of Authenticator
extension OAuthAuthenticator: DataCapturing.Authenticator {
    /**
     Unimplemented old style callback method. This method is bound to be removed soon, so no need to implement it.
     */
    func authenticate(onSuccess: @escaping (String) -> Void, onFailure: @escaping (Error) -> Void) {
        fatalError("Not implemented")
    }

    /**
     Authenticate with the AppAuth framework against an identity provider.
     */
    func authenticate() async throws -> String {
        os_log("Authentication: Starting Authentication", log: OSLog.authorization, type: .debug)
        os_log("Address used to access identity provider %@", log: OSLog.authorization, type: .debug)
        if let authState = loadState(OAuthAuthenticator.appAuthStateKey), authState.refreshToken != nil {
            let result: String = try await withCheckedThrowingContinuation { continuation in
                authState.performAction(freshTokens: { (accessToken, idToken, error) in
                    os_log("Authentication: Refreshed Authentication Information.", log: OSLog.authorization, type: .debug)
                    if let error = error as? NSError {
                        if error.code == -10, let callbackController = self.callbackController {
                            Task {
                                do {
                                    try await self.doAuth(presenting: callbackController)
                                    guard let accessToken = self.authState?.lastTokenResponse?.accessToken else {
                                        throw OAuthAuthenticatorError.tokenMissing
                                    }

                                    continuation.resume(returning: accessToken)
                                } catch {
                                    continuation.resume(throwing: error)
                                }
                            }
                        } else {
                            authState.update(withAuthorizationError: error)
                            self.authState = authState
                            continuation.resume(throwing: error)
                        }
                    } else if let accessToken = accessToken {
                        self.idToken = idToken
                        self.authState = authState
                        continuation.resume(returning: accessToken)
                    } else {
                        continuation.resume(throwing: OAuthAuthenticatorError.tokenMissing)
                    }
                })
            }

            return result
        } else if let callbackController = self.callbackController {
            try await doAuth(presenting: callbackController)

            guard let accessToken = authState?.lastTokenResponse?.accessToken else {
                throw OAuthAuthenticatorError.tokenMissing
            }

            return accessToken
        } else {
            throw RFRError.unableToAuthenticate
        }
        //}

    }

    func delete() async throws {
        let request: URLRequest = try await withCheckedThrowingContinuation { continuation in
            authState?.performAction { accessToken, idToken, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let accessToken = accessToken else {
                    continuation.resume(throwing: OAuthAuthenticatorError.tokenMissing)
                    return
                }

                do {
                    let authToken = try JWTToken(from: accessToken)
                    var deleteRequest = URLRequest(url: self.apiEndpoint.appending(component: "users").appending(path: authToken.decoded.sub.uuidString))

                    deleteRequest.httpMethod = "DELETE"
                    deleteRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                    continuation.resume(returning: deleteRequest)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }

        os_log("Authentication: Sending delete request to %@", log: OSLog.authorization, type: .debug, request.url!.absoluteString)
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OAuthAuthenticatorError.invalidResponse
        }

        guard httpResponse.statusCode == 202 else {
            throw OAuthAuthenticatorError.errorResponse(status: httpResponse.statusCode)
        }
    }

    func callback(url: URL) {
        os_log("Opened App via callback from @%.", log: OSLog.system, type: .info, url.absoluteString)

        if let authorizationFlow = self.currentAuthorizationFlow, authorizationFlow.resumeExternalUserAgentFlow(with: url) {
            currentAuthorizationFlow = nil
        }
    }

    /// Send logout request to identity server and reset AppAuth auth state.
    func logout() async throws {
        os_log("Authentication: Logging Out", log: OSLog.authorization, type: .debug)
        guard let idToken = self.idToken else {
            // TODO: Throw proper Exception here.
            fatalError()
        }



        let request = await OIDEndSessionRequest(
            // Was steht in den Metadaten und wo bekomme ich diese her?
            // Es ist eine OIDServiceConfiguration die als Parameter übergeben wird.
            // Was ist eine OIDServiceConfiguration. Von wo kommt der Parameter.
            // Das ist das Ergebnis des Discovery Calls.
            configuration: try serviceDiscovery(),
            // Welches Token ist das? Woher bekomme ich es?
            // Siehe: https://auth0.com/blog/id-token-access-token-what-is-the-difference/
            // Man bekommt es aus dem authroization request
            idTokenHint: idToken,
            // Wohin muss diese URL zeigen? Injezirt wird sie zum Beispiel per Konfigurationsdatei, ist also statisch.
            postLogoutRedirectURL: redirectUri,
            additionalParameters: nil
        )

        // Was ist eine user agent session? Wo kommt diese her?
        // Was passiert mit der userAgentSession noch? Warum muss sie als Attribut gespeichert werden?
        let _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<OIDEndSessionResponse, Error>) in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }

                let callbackController = rootViewController()
                let agent = OIDExternalUserAgentIOS(presenting: callbackController)
                self.currentAuthorizationFlow = OIDAuthorizationService.present(
                    request,
                    externalUserAgent: agent!
                    // Was muss dieser Handler machen, und wo kommt er her?
                ){ response, error in
                    os_log("Authentication: Received logout response.", log: OSLog.authorization, type: .debug)
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let response = response {
                        continuation.resume(returning: response)
                    } else {
                        continuation.resume(throwing: OAuthAuthenticatorError.missingResponse)
                    }
                }

                self.authState = nil
            }
        }

        self.idToken = nil
        os_log("Authentication: Finished logging out", log: OSLog.authorization, type: .debug)
    }
}

// MARK: - Error Handling
/**
 Errors thrown during user authentication against an OAuth identity provider.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
enum OAuthAuthenticatorError: Error {
    case tokenMissing
    case invalidToken
    case invalidResponse
    case errorResponse(status: Int)
    case missingAuthState(cause: Error?)
    case discoveryFailed(cause: String)
    case missingCallbackController
    case missingResponse
}

extension OAuthAuthenticatorError: LocalizedError {
    /// Internationalized human readable description of the error.
    var errorDescription: String? {
        return switch self {
        case .tokenMissing:
            NSLocalizedString(
                "de.cyface.error.oauthauthenticatorerror.tokenMissing",
                value: "No token received on token refresh!",
                comment: "Tell the user that you received no valid auth token on a refresh request. This should actually not happen and points to some serious implementation mistakes.")
        case .invalidResponse:
            NSLocalizedString(
                "de.cyface.error.oauthauthenticationerror.invalidResponse",
                value: "Response was not an HTTP response",
                comment: "Tell the user, that the response was not an HTTP response. This should not happen unless there is some serious implemenetation error."
            )
        case .errorResponse(let error):
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "de.cyface.error.oauthauthenticationerror.errorResponse",
                    value: "Received HTTP status code %d but expected 200",
                    comment: "Tell the user, that the wrong HTTP status code was recieved. It should be 200. The actual value is provided as the first argument."
                ),
                error
            )
        case .missingAuthState(cause: let cause):
            String.localizedStringWithFormat(NSLocalizedString(
                "de.cyface.error.oauthauthenticationerror.missingAuthState",
                value:
"""
There was no authentication state.
This must not happen and indicates a serious implementation error.
Please verify your App and reinstall if possible.
The reported cause for this error was: %s.
""",
                comment:
"""
Tell the user, that the internal auth state did not exist.
Since it is gracefully initialized before used for the first time, this is an error, that should not happen in production.
The cause of this error is provided as the first parameter.
"""
            ),
                                             cause?.localizedDescription ?? "cause unknown"
            )
        case .discoveryFailed(cause: let cause):
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "de.cyface.error.oauthauthenticationerror.discoveryFailed",
                    value:
"""
The authentication mechanism failed to discover its settings from the OAuth Discovery.
This was caused by %s.
""",
                    comment:
"""
Tell the user, that the OAuth discovery failed for some reason.
The actual reason is provided as a String message, as the first argument.
"""
                ),
                cause
            )
        case .missingCallbackController:
            NSLocalizedString(
                "de.cyface.error.oauthauthenticationerror.missingCallackController",
                value:
"""
Trying the call OAuth authentication without a controller to call upon returning to the app is invalid.
""",
                comment:
"""
Tell the user, that OAuth was called in a wrong state. Namely there was no ViewController provided to return to, after successful authentication.
"""
            )
        case .invalidToken:
            NSLocalizedString(
                "de.cyface.error.oauthauthenticationerror.invalidtoken",
                value: "Authentication was not formatted correctly and thus could not be decoded.",
                comment: "Tell the user that an invalid JWT token was encountered!"
            )
        case .missingResponse:
            NSLocalizedString(
                "de.cyface.error.oauthauthenticationerror.missingresponse",
                value: "OAuth request did not return either a response or an error! Unable to proceed with at least one of the two.",
                comment: "This error should not happen on a properly developed system. Tell the user to call for support!"
            )
        }
    }
}
