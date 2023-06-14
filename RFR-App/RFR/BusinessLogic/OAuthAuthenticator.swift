//
//  OAuthAuthenticator.swift
//  RFR
//
//  Created by Klemens Muthmann on 14.06.23.
//

import DataCapturing
import Alamofire
import Foundation

class OAuthAuthenticator {
    private static let decoder = JSONDecoder()
    private var issuer: URL
    private let clientId: String
    private let clientSecret: String
    private var token: String?
    private var refreshToken: String?
    var credentials: Credentials?

    init(issuer: URL, clientId: String, clientSecret: String) {
        self.issuer = issuer
        self.clientId = clientId
        self.clientSecret = clientSecret
    }
}

extension OAuthAuthenticator: CredentialsAuthenticator {

    var username: String? {
        get {
            credentials?.username
        }
        set {
            if let newValue = newValue {
                if self.credentials == nil {
                    self.credentials = Credentials(username: newValue)
                } else {
                    credentials?.username = newValue
                }
            } else {
                credentials = nil
            }
        }
    }

    var password: String? {
        get {
            credentials?.password
        }
        set {
            if let newValue = newValue {
                if self.credentials == nil {
                    self.credentials = Credentials(password: newValue)
                } else {
                    credentials?.password = newValue
                }
            } else {
                credentials = nil
            }
        }
    }

    var authenticationEndpoint: URL {
        set {
            issuer = newValue
        }
        get {
            self.issuer
        }
    }

    func authenticate(onSuccess: @escaping (String) -> Void, onFailure: @escaping (Error) -> Void) {

    }

    func authenticate() async throws -> String {
        guard let credentials = credentials else {
            throw RFRError.missingCredentials
        }

        let address = issuer
            .appending(component: "protocol")
            .appending(component: "openid-connect")
            .appending(component: "token")

        //let headers: HTTPHeaders = ["Content-Type":"application/x-www-form-urlencoded"]
        let parameters = [
            "client_id":clientId,
            "username":credentials.username,
            "password":credentials.password,
            "grant_type":"password",
            "client_secret":clientSecret,
            "scope":"openid"
        ]

        return try await withCheckedThrowingContinuation { continuation in
            AF.request(
                address,
                method: .post,
                parameters: parameters
            )
            .validate(statusCode: 200...200)
            .response { response in
                if let bodyData = response.data {
                    do {
                        let tokenData = try OAuthAuthenticator.decoder.decode(TokenData.self, from: bodyData)
                        continuation.resume(returning: tokenData.accessToken)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                } else {
                    continuation.resume(throwing: RFRError.missingAuthenticationBody)
                }
            }
            .resume()
        }
    }
}

struct TokenData: Codable {
    let accessToken: String
    let expiresIn: UInt64
    let refreshExpiresIn: UInt64
    let refreshToken: String
    let tokenType: String
    let idToken: String
    let notBeforePolicy: Int
    let sessionState: String
    let scope: String

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshExpiresIn = "refresh_expires_in"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case idToken = "id_token"
        case notBeforePolicy = "not-before-policy"
        case sessionState = "session_state"
        case scope
    }
}

/*
 "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJLU2VlSDc4QWNjdU1teURRNmVQYnNLWG5CU1dCYldmeGxWOFNLSTU2c004In0.eyJleHAiOjE2ODY3NDE0NDksImlhdCI6MTY4Njc0MTE0OSwianRpIjoiNmM2Y2ExOGYtMTdjYi00NTFiLWJlMDMtZTk3ZjMxMjhmNGYyIiwiaXNzIjoiaHR0cHM6Ly9hdXRoLmN5ZmFjZS5kZTo4NDQzL3JlYWxtcy9yZnIiLCJhdWQiOiJhY2NvdW50Iiwic3ViIjoiNTFhYzYyYmEtZmExZi00YjM0LWEyOWMtNTcxNjFjYjU3ZWRhIiwidHlwIjoiQmVhcmVyIiwiYXpwIjoiaW9zLWFwcCIsInNlc3Npb25fc3RhdGUiOiJmN2UwNWNhOS01N2I2LTQwMTAtYmVjMS01Mjg4NmY5ZDU0MDQiLCJhY3IiOiIxIiwicmVhbG1fYWNjZXNzIjp7InJvbGVzIjpbIm9mZmxpbmVfYWNjZXNzIiwiZGVmYXVsdC1yb2xlcy1yZnIiLCJ1bWFfYXV0aG9yaXphdGlvbiJdfSwicmVzb3VyY2VfYWNjZXNzIjp7ImFjY291bnQiOnsicm9sZXMiOlsibWFuYWdlLWFjY291bnQiLCJtYW5hZ2UtYWNjb3VudC1saW5rcyIsInZpZXctcHJvZmlsZSJdfX0sInNjb3BlIjoib3BlbmlkIHByb2ZpbGUgZW1haWwiLCJzaWQiOiJmN2UwNWNhOS01N2I2LTQwMTAtYmVjMS01Mjg4NmY5ZDU0MDQiLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwibmFtZSI6IktsZW1lbnMgTXV0aG1hbm4iLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJrbGVtZW5zLm11dGhtYW5uQGN5ZmFjZS5kZSIsImdpdmVuX25hbWUiOiJLbGVtZW5zIiwiZmFtaWx5X25hbWUiOiJNdXRobWFubiIsImVtYWlsIjoia2xlbWVucy5tdXRobWFubkBjeWZhY2UuZGUifQ.TRR1VfBKCxaRnZs0TUM2YDvv25wD_c3gcpZNLX9gJuSqZdIrkWd_ruGHC3HwPSrbP2b-PPnrV2XaoWE8qrSMX7yC3c1poYrx9GS_JIsBDLCEzRHUsgJg3xxbLcRdNvscUrcXDmDNATrInHjorql7Gsk1JYXOBYCU3c-FFaSu8KmJq1gVVOgXl4zCqsxMeMdVbFg3kUYloiCUzmhVESSbWz-Tm_RqP3qFqn2vor7F7K2gulF2DwTXQPZfahJLqQ383XcjfDybx3BkW9irePHn7u_jvmXKUmp-FjCJ1NHZrlxgX1iZcS1iI2pPM6V6k0Q3ebpD-lmHW_KveXrL0lwL-g",
     "expires_in": 300,
     "refresh_expires_in": 86313600,
     "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICI1ZGM4NjMyMi04ZDM4LTRmMTctODllNC1mNTY1ZDNlMmMzNjgifQ.eyJleHAiOjE3NzMwNTQ3NDksImlhdCI6MTY4Njc0MTE0OSwianRpIjoiYWExZjBhOTItODhlZi00MDRiLTk0N2YtMTczYTRmMzZjMGYxIiwiaXNzIjoiaHR0cHM6Ly9hdXRoLmN5ZmFjZS5kZTo4NDQzL3JlYWxtcy9yZnIiLCJhdWQiOiJodHRwczovL2F1dGguY3lmYWNlLmRlOjg0NDMvcmVhbG1zL3JmciIsInN1YiI6IjUxYWM2MmJhLWZhMWYtNGIzNC1hMjljLTU3MTYxY2I1N2VkYSIsInR5cCI6IlJlZnJlc2giLCJhenAiOiJpb3MtYXBwIiwic2Vzc2lvbl9zdGF0ZSI6ImY3ZTA1Y2E5LTU3YjYtNDAxMC1iZWMxLTUyODg2ZjlkNTQwNCIsInNjb3BlIjoib3BlbmlkIHByb2ZpbGUgZW1haWwiLCJzaWQiOiJmN2UwNWNhOS01N2I2LTQwMTAtYmVjMS01Mjg4NmY5ZDU0MDQifQ.gCSJz1gBNGvrjOKpYPGPWdxVEkiQAalcGjhY0H2atUc",
     "token_type": "Bearer",
     "id_token": "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJLU2VlSDc4QWNjdU1teURRNmVQYnNLWG5CU1dCYldmeGxWOFNLSTU2c004In0.eyJleHAiOjE2ODY3NDE0NDksImlhdCI6MTY4Njc0MTE0OSwiYXV0aF90aW1lIjowLCJqdGkiOiI4YWQ3Mjk0Mi0xODBjLTQxYzgtODhjYi1hM2FmZWQ3ZDZhMzciLCJpc3MiOiJodHRwczovL2F1dGguY3lmYWNlLmRlOjg0NDMvcmVhbG1zL3JmciIsImF1ZCI6Imlvcy1hcHAiLCJzdWIiOiI1MWFjNjJiYS1mYTFmLTRiMzQtYTI5Yy01NzE2MWNiNTdlZGEiLCJ0eXAiOiJJRCIsImF6cCI6Imlvcy1hcHAiLCJzZXNzaW9uX3N0YXRlIjoiZjdlMDVjYTktNTdiNi00MDEwLWJlYzEtNTI4ODZmOWQ1NDA0IiwiYXRfaGFzaCI6InZGTGw3NDhwcTNxcTVocGtSQ01OX0EiLCJhY3IiOiIxIiwic2lkIjoiZjdlMDVjYTktNTdiNi00MDEwLWJlYzEtNTI4ODZmOWQ1NDA0IiwiZW1haWxfdmVyaWZpZWQiOnRydWUsIm5hbWUiOiJLbGVtZW5zIE11dGhtYW5uIiwicHJlZmVycmVkX3VzZXJuYW1lIjoia2xlbWVucy5tdXRobWFubkBjeWZhY2UuZGUiLCJnaXZlbl9uYW1lIjoiS2xlbWVucyIsImZhbWlseV9uYW1lIjoiTXV0aG1hbm4iLCJlbWFpbCI6ImtsZW1lbnMubXV0aG1hbm5AY3lmYWNlLmRlIn0.oRyfCY0YDnK_mUlUxzfK9iBaxCdpxG4Up-bUua97niUS4jIyzScjPCPjp0P_bQlGSd9FGeHTPG90Uxm3L8VgvvHsvku0CqNu887q3N7odCP08PuSRFd9TTe36I2ZF0wNVO7WnJZkRQvO242c43jbxR6dD6VF-gP-QTal-gcj5ARNri5LPgtBP6GY38GPQHODbc_iVZUuFqci6PvdnjfCUbkNR3dhxnf71SlXTCJUR7nDY4TB1bY3oKlMrWftDpdRavzebvr3VuM9UCrElizYkJgreBfHC2nnj1a0_cCSw60-UfIhyhL8PRwNRF7AmThlQ1JzwjF4lRoeCEjfelYy4Q",
     "not-before-policy": 0,
     "session_state": "f7e05ca9-57b6-4010-bec1-52886f9d5404",
     "scope": "openid profile email"
 */
