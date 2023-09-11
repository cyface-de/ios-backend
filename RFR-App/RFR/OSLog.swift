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
    static let synchronization = OSLog(subsystem: subsystem, category: "synchronization")
    static let measurement = OSLog(subsystem: subsystem, category: "measurement")
    static let authorization = OSLog(subsystem: subsystem, category: "authorization")
    static let system = OSLog(subsystem: subsystem, category: "system")
}
