//
//  OAuthAuthenticator.swift
//  RFR
//
//  Created by Klemens Muthmann on 22.08.23.
//

import Foundation
import AppAuth
import Alamofire
import DataCapturing

struct OAuthAuthenticator: DataCapturing.Authenticator {
    func authenticate(onSuccess: @escaping (String) -> Void, onFailure: @escaping (Error) -> Void) {
        fatalError("Not implemented")
    }


    static let appAuthStateKey = "de.cyface.authstate"
    private static let uploadRequestTime = 10_000

    func authenticate() async throws -> String {
        /*if let accessToken = authState.lastTokenResponse?.accessToken {
            if let validTokenTime = authState.lastTokenResponse?.accessTokenExpirationDate?.timeIntervalSinceNow, validTokenTime > OAuthAuthenticator.uploadRequestTime {
                return accessToken
            }
        } else if let refreshToken = authState.refreshToken {*/
        let authState = OAuthAuthenticator.loadState(OAuthAuthenticator.appAuthStateKey)
        let result: String = try await withCheckedThrowingContinuation { continuation in
            authState?.performAction(freshTokens: { (accessToken, idToken, error) in
                // TODO: Do I need to update authState here?
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

    static func saveState(_ authState: OIDAuthState?, _ appAuthStateKey: String) {
        if let authState = authState {
            let archivedAuthState = NSKeyedArchiver.archivedData(withRootObject: authState)
            UserDefaults.standard.set(archivedAuthState, forKey: appAuthStateKey)
        } else {
            UserDefaults.standard.removeObject(forKey: appAuthStateKey)
        }
        UserDefaults.standard.synchronize()
    }

    static func loadState(_ appAuthStateKey: String) -> OIDAuthState? {
        if let archivedAuthState = UserDefaults.standard.object(forKey: appAuthStateKey) as? Data {
            if let authState = NSKeyedUnarchiver.unarchiveObject(with: archivedAuthState) as? OIDAuthState {
                return authState
            }
        }
        return nil
    }

}

enum OAuthAuthenticatorError: Error {
    case tokenMissing
}

extension OAuthAuthenticatorError: LocalizedError {
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
