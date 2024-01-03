//
//  File.swift
//  
//
//  Created by Klemens Muthmann on 11.04.23.
//

import Foundation
import OSLog

extension OSLog {
    public static var subsystem = Bundle.main.bundleIdentifier!

    static let persistence = OSLog(subsystem: subsystem, category: "persistence")
    static let capturing = OSLog(subsystem: subsystem, category: "capturing")
    static let sensor = OSLog(subsystem: subsystem, category: "sensor")
    static let measurement = OSLog(subsystem: subsystem, category: "measurement")
}
