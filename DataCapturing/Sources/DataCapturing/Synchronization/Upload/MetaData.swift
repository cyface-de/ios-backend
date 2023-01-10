/*
 * Copyright 2022 Cyface GmbH
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
import Alamofire

/// A name that tells the system which kind of iOS device this is.
var modelIdentifier: String {
    if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] { return simulatorModelIdentifier }
    var sysinfo = utsname()
    uname(&sysinfo) // ignore return value
    return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
}

/**
 A globally unique identifier of this device. This is used to separate data transmitted by one device from data transmitted by another one on the server side. An installation identifier is not device specific for technical and data protection reasons it is recreated every time the app is reinstalled.
 */
var installationIdentifier: String {
    if let applicationIdentifier = UserDefaults.standard.string(forKey: "de.cyface.identifier") {
        return applicationIdentifier
    } else {
        let applicationIdentifier = UUID.init().uuidString
        UserDefaults.standard.set(applicationIdentifier, forKey: "de.cyface.identifier")
        return applicationIdentifier
    }
}

/**
 A measurement's meta data, required by the server to decide on whether to accept the upload or not.

 - author: Klemens Muthmann
 - version: 1.0.0
 */
struct MetaData: Encodable {
    /// The number of locations of the transmittable measurement.
    let locationCount: UInt64
    /// The data format used to encode the payload data.
    let formatVersion: Int
    /// The latitude of the first location in the transmitted measurement, or `nil` if no locations where captured.
    let startLocLat: Double?
    /// The longitude of the first location in the transmitted measurement, or `nil` if no locations where captured.
    let startLocLon: Double?
    /// The timestamp of the first location in the transmitted measurement, or `nil` if no locations where captured.
    let startLocTS: UInt64?
    /// The latitude of the last location in the transmitted measurement, or `nil` if no locations where captured.
    let endLocLat: Double?
    /// The longitude of the last location in the transmitted measurement, or `nil` if no locations where captured.
    let endLocLon: Double?
    /// The timestamp of the last location in the transmitted measurement, or `nil` if no locations where captured.
    let endLocTS: UInt64?
    /// The system wide unique identifier of the transmitted measurement.
    let measurementId: UInt64
    /// The  version of the operation system, when transmitting the measurement.
    let osVersion: String
    /// The current version of the Cyface application transmitting the measurement.
    let applicationVersion: String
    /// The length of the transmitted measurement in meters.
    let length: Double
    /// The starting modalitiy used for capturing the measurement.
    let modality: String
    /// The world wide unique identifier of the current application installation.
    let deviceId = installationIdentifier
    /// The type of the device transmitting the data.
    let deviceType = modelIdentifier

    /// The meta data formatted as HTTP header data.
    var asHeader: HTTPHeaders {
        var headers: HTTPHeaders = [
            "Content-Type": "application/octet-stream",
            "deviceId": deviceId,
            "measurementId": String(measurementId),
            "locationCount": String(locationCount),
            "formatVersion": String(formatVersion),
            "deviceType": deviceType,
            "osVersion": osVersion,
            "appVersion": applicationVersion,
            "length": String(length),
            "modality": modality
        ]
        if let startLocLat = startLocLat {
            headers.add(name: "startLocLat", value: String(startLocLat))
        }
        if let startLocLon = startLocLon {
            headers.add(name: "startLocLon", value: String(startLocLon))
        }
        if let startLocTS = startLocTS {
            headers.add(name: "startLocTS", value: String(startLocTS))
        }
        if let endLocLat = endLocLat {
            headers.add(name: "endLocLat", value: String(endLocLat))
        }
        if let endLocLon = endLocLon {
            headers.add(name: "endLocLon", value: String(endLocLon))
        }
        if let endLocTS = endLocTS {
            headers.add(name: "endLocTS", value: String(endLocTS))
        }

        return headers
    }
}
