/*
 * Copyright 2023 Cyface GmbH
 *
 * This file is part of the Ready for Robots iOS App.
 *
 * The Ready for Robots iOS App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Ready for Robots iOS App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Ready for Robots iOS App. If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation

/**
 Represents a Json configuration of this application.

 Each property from the Json file is mapped to a property of this class.
 Use a ``ConfigLoader`` to create an instance.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.2
 */
struct Config: Decodable {
    // MARK: - Properties
    /// The URL of the identity provider used to authorize users with this application.
    let issuer: String
    /// The identifier of this client as recognized by its identity provider.
    let clientId: String
    /// The URI used by the identity provider after successful authentication to give control back to this application.
    let redirectUri: String
    /// A URL to a Cyface Data Collector used to upload data to.
    let uploadEndpoint: String
    /// A URL to a Cyface incentives service used to provide additional value for the user.
    let incentivesUrl: String
    /// A URL to a Cyface Data Provider. This is currently mainly used to provide user delete functionality.
    let apiEndpoint: String
    /// Whether to enable tracing for sentry or not. This causes a big performance hit and should not happen in production.
    let enableSentryTracing: String

    // MARK: - Initializers
    /// Create a new config with empty values.
    init() {
        self.issuer = ""
        self.clientId = ""
        self.redirectUri = ""
        self.uploadEndpoint = ""
        self.incentivesUrl = ""
        self.apiEndpoint = ""
        self.enableSentryTracing = ""
    }

    // MARK: - Methods
    /// Parse the ``issuer`` as a proper ``URL`` object.
    func getIssuerUri() throws -> URL {
        guard let url = URL(string: self.issuer) else {
            throw RFRError.invalidUrl(url: self.issuer)
        }

        return url
    }

    /// Parse the ``redirectUri`` as a proper ``URL`` object.
    func getRedirectUri() throws -> URL {
        guard let url = URL(string: self.redirectUri) else {
            throw RFRError.invalidUrl(url: self.redirectUri)
        }

        return url
    }

    /// Parse the ``uploadEndpoint`` as a proper ``URL`` object.
    func getUploadEndpoint() throws -> URL {
        guard let url = URL(string: self.uploadEndpoint) else {
            throw RFRError.invalidUrl(url: self.uploadEndpoint)
        }

        return url
    }

    /// Parse the ``incentivesUrl`` as a proper ``URL`` object.
    func getIncentivesUrl() throws -> URL {
        guard let url = URL(string: self.incentivesUrl) else {
            throw RFRError.invalidUrl(url: self.incentivesUrl)
        }

        return url
    }

    /// Parse the ``issuer`` as a proper ``URL`` object.
    func getApiEndpoint() throws -> URL {
        guard let url = URL(string: self.apiEndpoint) else {
            throw RFRError.invalidUrl(url: self.apiEndpoint)
        }

        return url
    }

    func getEnableSentryTracing() throws -> Bool {
        let ret = (enableSentryTracing as NSString).boolValue
        return ret
    }
}
