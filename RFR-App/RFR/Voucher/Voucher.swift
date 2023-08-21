//
//  Voucher.swift
//  RFR
//
//  Created by Klemens Muthmann on 04.06.23.
//

import Foundation
import Alamofire
import DataCapturing

class Vouchers {
    private static let decoder = JSONDecoder()
    let authenticator: any DataCapturing.Authenticator
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

    init(authenticator: any DataCapturing.Authenticator, url: URL) {
        self.authenticator = authenticator
        self.url = url
    }

    func requestVoucher() async throws -> Voucher {
        if let voucher = self._voucher {
            return voucher
        } else {
            let token = try await authenticator.authenticate()
            let headers: HTTPHeaders = [
                "Authorization": "Bearer \(token)",
                "Accept": "application/json"
            ]
            let voucherURL = url.appending(component: "voucher")

            let voucher = try await withUnsafeThrowingContinuation { continuation in
                let request = AF
                    .request(voucherURL, headers: headers)
                    .validate()
                    .response { response in
                        do {
                            if let body = response.data {
                                let voucher = try Vouchers.decoder.decode(Voucher.self, from: body)
                                continuation.resume(returning: voucher)
                            }
                        } catch {
                            continuation.resume(throwing: error)
                        }
                }
                request.resume()
            }
            self._voucher = voucher

            return voucher
        }
    }

    private func requestCount() async throws -> Int {
        if let count = _count {
            return count
        } else {
            let token = try await authenticator.authenticate()

            let headers: HTTPHeaders = [
                "Authorization": "Bearer \(token)",
                "Accept": "application/json"
            ]

            let incentivesCountURL = url.appending(component:"voucher_count")

            return try await withCheckedThrowingContinuation { continuation in
                AF.request(incentivesCountURL, headers: headers).validate().responseData { response in

                    switch response.result {
                    case .failure(let failure):
                        continuation.resume(throwing: VoucherRequestError.requestFailed(cause: failure))
                    case .success:
                        if let body = response.data {
                            do {
                                let voucherCount = try Vouchers.decoder.decode(Count.self, from: body)
                                self._count = voucherCount.vouchers
                                continuation.resume(returning: voucherCount.vouchers)
                            } catch {
                                continuation.resume(throwing: error)
                            }
                        } else {
                            continuation.resume(throwing: VoucherRequestError.noData)
                        }
                    }
                }.resume()
            }
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
    case noData
    case requestFailed(cause: AFError)
}
