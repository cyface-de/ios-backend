/*
 * Copyright 2023 Cyface GmbH
 *
 * This file is part of the Ready for Robots iOS App.
 *
 * The Ready for Robots iOS App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Ready for Robots iOS App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Ready for Robots iOS App. If not, see <http://www.gnu.org/licenses/>.
 */
import Foundation
import OSLog

extension OSLog {
    /// The subsystem to log to should equal our bundle identifier
    private static var subsystem = Bundle.main.bundleIdentifier!

    /// Logs for data capturing events.
    static let capturingEvent = OSLog(subsystem: subsystem, category: "capturing")
    /// Logs for data synchronization events.
    static let synchronization = OSLog(subsystem: subsystem, category: "synchronization")
    /// Logs concerning loading and storing information about measurements.
    static let measurement = OSLog(subsystem: subsystem, category: "measurement")
    /// Logs concerning user authentication and authorization.
    static let authorization = OSLog(subsystem: subsystem, category: "authorization")
    /// System level logs.
    static let system = OSLog(subsystem: subsystem, category: "system")
}
