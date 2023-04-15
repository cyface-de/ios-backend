//
//  Formatter.swift
//  RFR
//
//  Created by Klemens Muthmann on 13.04.23.
//

import Foundation

let speedFormatter = {
    let nf = NumberFormatter()
    nf.minimumFractionDigits = 1
    nf.maximumFractionDigits = 2
    nf.multiplier = 3.6

    return nf
}()
let locationFormatter = {
    let nf = NumberFormatter()
    nf.minimumFractionDigits = 1
    nf.maximumFractionDigits = 5

    return nf
}()
let emissionsFormatter = {
    let nf = NumberFormatter()
    nf.minimumFractionDigits = 1
    nf.maximumFractionDigits = 3

    return nf
}()
let distanceFormatter = {
    let nf = NumberFormatter()
    nf.minimumFractionDigits = 1
    nf.maximumFractionDigits = 3
    nf.multiplier = 0.001

    return nf
}()
let timeFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute, .second]
    formatter.zeroFormattingBehavior = .pad

    return formatter
}()
let riseFormatter = {
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 1
    formatter.maximumFractionDigits = 1

    return formatter
}()
