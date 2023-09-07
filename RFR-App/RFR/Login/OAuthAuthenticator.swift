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
import Alamofire
import DataCapturing

/**
 An ``DataCapturing.Authenticator`` implementation to realize an OAuth Auth flow.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
struct OAuthAuthenticator: DataCapturing.Authenticator {
    /**
     Unimplemented old style callback method. This method is bound to be removed soon, so no need to implement it.
     */
    func authenticate(onSuccess: @escaping (String) -> Void, onFailure: @escaping (Error) -> Void) {
        fatalError("Not implemented")
    }

    /**
     The key used to identify the stored authentication state within the system shared preferences.
     */
    static let appAuthStateKey = "de.cyface.authstate"

    /**
     Authenticate with the AppAuth framework against an identity provider.
     */
    func authenticate() async throws -> String {
        /*if let accessToken = authState.lastTokenResponse?.accessToken {
            if let validTokenTime = authState.lastTokenResponse?.accessTokenExpirationDate?.timeIntervalSinceNow, validTokenTime > OAuthAuthenticator.uploadRequestTime {
                return accessToken
            }
        } else if let refreshToken = authState.refreshToken {*/
        let authState = OAuthAuthenticator.loadState(OAuthAuthenticator.appAuthStateKey)
        let result: String = try await withCheckedThrowingContinuation { continuation in
            authState?.performAction(freshTokens: { (accessToken, idToken, error) in
                if let error = error {
                    authState?.update(withAuthorizationError: error)
                    OAuthAuthenticator.saveState(authState, OAuthAuthenticator.appAuthStateKey)
                    continuation.resume(throwing: error)
                } else if let accessToken = accessToken {
                    OAuthAuthenticator.saveState(authState, OAuthAuthenticator.appAuthStateKey)
                    continuation.resume(returning: accessToken)
                } else {
                    continuation.resume(throwing: OAuthAuthenticatorError.tokenMissing)
                }
            })
        }

        return result
        //}
    }

    /// Store the authentication state between application restarts.
    static func saveState(_ authState: OIDAuthState?, _ appAuthStateKey: String) {
        if let authState = authState {
            let archivedAuthState = NSKeyedArchiver.archivedData(withRootObject: authState)
            UserDefaults.standard.set(archivedAuthState, forKey: appAuthStateKey)
        } else {
            UserDefaults.standard.removeObject(forKey: appAuthStateKey)
        }
        UserDefaults.standard.synchronize()
    }

    /// Load the authentication state after an application restart.
    static func loadState(_ appAuthStateKey: String) -> OIDAuthState? {
        if let archivedAuthState = UserDefaults.standard.object(forKey: appAuthStateKey) as? Data {
            if let authState = NSKeyedUnarchiver.unarchiveObject(with: archivedAuthState) as? OIDAuthState {
                return authState
            }
        }
        return nil
    }

}

/**
 Errors thrown during user authentication against an OAuth identity provider.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
enum OAuthAuthenticatorError: Error {
    case tokenMissing
}

extension OAuthAuthenticatorError: LocalizedError {
    /// Internationalized human readable description of the error.
    var errorDescription: String? {
        switch self {
        case .tokenMissing:
            let errorMessage = NSLocalizedString(
                "de.cyface.error.oauthauthenticatorerror.tokenMissing",
                value: "No token received on token refresh!",
                comment: "Tell the user that you received no valid auth token on a refresh request. This should actually not happen and points to some serious implementation mistakes.")

            return errorMessage
        }
    }
}
