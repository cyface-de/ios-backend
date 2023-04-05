//
//  OSLog.swift
//  RFR
//
//  Created by Klemens Muthmann on 31.03.23.
//

import Foundation
import OSLog

extension OSLog {
    private static var subsystem = Bundle.main.bundleIdentifier!

    static let capturingEvent = OSLog(subsystem: subsystem, category: "capturing")
}
