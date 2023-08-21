//
//  VoucherOverviewModel.swift
//  RFR
//
//  Created by Klemens Muthmann on 19.06.23.
//

import Foundation

class VoucherOverviewModel {
    let accumulatedKilometers: Double
    let kilometersToAcquire: Double
    let voucherCount: Int

    init(accumulatedKilometers: Double, kilometersToAcquire: Double, voucherCount: Int) {
        self.accumulatedKilometers = accumulatedKilometers
        self.kilometersToAcquire = kilometersToAcquire
        self.voucherCount = voucherCount
    }

    func accumulatedKilometersLabel() throws -> String {
        guard let formattedAccumulatedKilometers = countFormatter.string(from: accumulatedKilometers as NSNumber) else {
            throw RFRError.formattingFailed(number: accumulatedKilometers as NSNumber)
        }

        return formattedAccumulatedKilometers
    }

    func kilometersToAcquireLabel() throws -> String {
        guard let formattedKilometersToAcquire = countFormatter.string(from: kilometersToAcquire as NSNumber) else {
            throw RFRError.formattingFailed(number: kilometersToAcquire as NSNumber)
        }

        return formattedKilometersToAcquire
    }
}
