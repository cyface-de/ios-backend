//
//  OAuthTest.swift
//  RFRTests
//
//  Created by Klemens Muthmann on 14.06.23.
//

import XCTest
@testable import RFR

final class OAuthTest: XCTestCase {

    /// This test requires a working identity provider to run, so it is set to be ignored by default.
    func ignore_test() async throws {
        let authenticator = OAuthAuthenticator(
            issuer: URL(string: "https://auth.cyface.de:8443/realms/rfr/")!,
            clientId: "ios-app",
            clientSecret: "lj2nKA9PbKnMdYej1hqxtm8pCoGxLcgL"
        )
        authenticator.password = "{Add Username here}"
        authenticator.username = "{Add Password here}"

        let token = try await authenticator.authenticate()

        XCTAssertTrue(token.starts(with: "ey"))
    }
}
