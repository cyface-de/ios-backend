/*
 * Copyright 2023 Cyface GmbH
 *
 * This file is part of the Ready for Robots App.
 *
 * The Ready for Robots App is free software: you can redistribute it and/or modify
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
    private static var subsystem = Bundle.main.bundleIdentifier!

    static let capturingEvent = OSLog(subsystem: subsystem, category: "capturing")
    static let synchronization = OSLog(subsystem: subsystem, category: "synchronization")
    static let measurement = OSLog(subsystem: subsystem, category: "measurement")
    static let authorization = OSLog(subsystem: subsystem, category: "authorization")
    static let system = OSLog(subsystem: subsystem, category: "system")
}
