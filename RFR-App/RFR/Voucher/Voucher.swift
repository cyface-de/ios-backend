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
 * The Ready for Robots App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Ready for Robots App. If not, see <http://www.gnu.org/licenses/>.
 */
import Foundation
import DataCapturing

/**
 Model object representing the collection of vouchers on the server.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
protocol Vouchers {
    var count: Int { get async throws }
    func requestVoucher() async throws -> Voucher
}
/**
 This class is responsible for creating the connection to the voucher API, retrieving vouchers and that state of the collection of vouchers.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.2
 */
class VouchersApi: Vouchers {
    
    // MARK: - Static Properties
    /// Used to decode JSON server responses.
    private static let decoder = JSONDecoder()
    // MARK: - Properties
    /// Used to authenticate with the voucher Server.
    let authenticator: DataCapturing.Authenticator
    /// The internet address of the root of the voucher API.
    let url: URL
    /// the number of vouchers available on the server.
    var count: Int {
        get async throws {
            return try await requestCount()
        }
    }
    /// Local cache for the number of vouchers on the server.
    private var _count: Int?
    /// Get the next valid voucher.
    private var voucher: Voucher {
        get async throws {
            return try await requestVoucher()
        }
    }
    /// Local cache for the last retrieved valid voucher from the server.
    private var _voucher: Voucher?

    // MARK: - Initializers
    /// Create a new object of this class, using the provided authenticator to authenticate with the auth server and using the API at the provided `url`.
    init(authenticator: DataCapturing.Authenticator, url: URL) {
        self.authenticator = authenticator
        self.url = url
    }

    // MARK: - Methods
    /// Returns the next valid voucher or a local copy.
    /// Each user can get a new voucher only once.
    /// As soon as the first voucher has been retrieved, a call to this method is going to return the same voucher each time.
    func requestVoucher() async throws -> Voucher {
        if let voucher = self._voucher {
            return voucher
        } else {
            let token = try await authenticator.authenticate()
            let voucherURL = url.appending(component: "voucher")

            var request = URLRequest(url: voucherURL)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let response = response as? HTTPURLResponse else {
                throw VoucherRequestError.invalidResponse
            }

            guard response.statusCode==200 else {
                throw VoucherRequestError.requestFailed(statusCode: response.statusCode)
            }

            let voucher = try VouchersApi.decoder.decode(Voucher.self, from: data)

            self._voucher = voucher

            return voucher
        }
    }

    // MARK: - Private Methods
    /// Provide the count of valid vouchers from the server or from local cache.
    /// This means that the count is not always up to date.
    private func requestCount() async throws -> Int {
        if let count = _count {
            return count
        } else {
            let token = try await authenticator.authenticate()

            let incentivesCountURL = url.appending(component:"voucher_count")

            var request = URLRequest(url: incentivesCountURL)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let response = response as? HTTPURLResponse else {
                throw VoucherRequestError.invalidResponse
            }

            guard response.statusCode == 200 else {
                throw VoucherRequestError.requestFailed(statusCode: response.statusCode)
            }

            let voucherCount = try VouchersApi.decoder.decode(Count.self, from: data)
            self._count = voucherCount.vouchers

            return voucherCount.vouchers
        }
    }
}

// MARK: - Support Structures
/**
 A struct representing a single voucher as returned by the server.

 This is required by the Swift `JSONDecoder` to decode responses from the server.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.2
 */
struct Voucher: Codable {
    let code: String
}

/**
 A struct representing the count of vouchers still available on the server.

 This is required by the Swift `JSONDecoder` to decode responses from the server.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.2
 */
struct Count: Codable {
    let vouchers: Int
}

/**
 Errors that might occur while communicating with the voucher API.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.2
 */
enum VoucherRequestError: Error {
    /// If the HTTP status code is not as expected.
    case requestFailed(statusCode: Int)
    /// If the response received is no valid `HTTPURLResponse`.
    case invalidResponse
}
