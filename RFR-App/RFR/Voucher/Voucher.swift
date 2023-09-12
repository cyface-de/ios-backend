//
//  Voucher.swift
//  RFR
//
//  Created by Klemens Muthmann on 04.06.23.
//

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
