//
//  File.swift
//  
//
//  Created by Klemens Muthmann on 18.03.24.
//

import Foundation

public extension Double {
    public func equal(_ value: Double, precise: Int) -> Bool {
        let denominator: Double = pow(10.0, Double(precise))
        let maxDiff: Double = 1 / denominator
        let realDiff: Double = self - value

        if fabs(realDiff) <= maxDiff {
            return true
        } else {
            return false
        }
    }
}
