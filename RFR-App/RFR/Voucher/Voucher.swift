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
import DataCapturing

class Vouchers {
    private static let decoder = JSONDecoder()
    let authenticator: DataCapturing.Authenticator
    let url: URL
    var count: Int {
        get async throws {
            return try await requestCount()
        }
    }
    private var _count: Int?
    private var voucher: Voucher {
        get async throws {
            return try await requestVoucher()
        }
    }
    private var _voucher: Voucher?

    init(authenticator: DataCapturing.Authenticator, url: URL) {
        self.authenticator = authenticator
        self.url = url
    }

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

            let voucher = try Vouchers.decoder.decode(Voucher.self, from: data)

            self._voucher = voucher

            return voucher
        }
    }

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

            let voucherCount = try Vouchers.decoder.decode(Count.self, from: data)
            self._count = voucherCount.vouchers

            return voucherCount.vouchers
        }
    }
}

struct Voucher: Codable {
    let code: String
    let until: String
}

struct Count: Codable {
    let vouchers: Int
}

enum VoucherRequestError: Error {
    /// If the HTTP status code is not as expected.
    case requestFailed(statusCode: Int)
    /// If the response received is no valid `HTTPURLResponse`.
    case invalidResponse
}
