/*
 * Copyright 2023-2024 Cyface GmbH
 *
 * This file is part of the Cyface SDK for iOS.
 *
 * The Cyface SDK for iOS is free software: you can redistribute it and/or modify
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
import OSLog

extension OSLog {
    /// The Subsystem identifies all messages comming from the Cyface SDK
    public static var subsystem = Bundle.main.bundleIdentifier!

    /// Messages related to storing and loading data.
    static let persistence = OSLog(subsystem: subsystem, category: "persistence")
    /// Messages related to the data capturing process.
    static let capturing = OSLog(subsystem: subsystem, category: "capturing")
    /// Messages related to capturing sensor data.
    static let sensor = OSLog(subsystem: subsystem, category: "sensor")
    /// Messages related to the workings of a measurement.
    static let measurement = OSLog(subsystem: subsystem, category: "measurement")
    /// Messages related to captured data synchronization.
    static let synchronization = OSLog(subsystem: subsystem, category: "synchronization")
    /// Messages related to authorization with a Cyface server.
    static let authorization = OSLog(subsystem: subsystem, category: "authorization")
    /// Messages related to interaction with iOS.
    static let system = OSLog(subsystem: subsystem, category: "system")
}
