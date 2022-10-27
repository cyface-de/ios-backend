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

/// The different modalities supported, by the Cyface iOS App.
///
/// - author: Klemens Muthmann
/// - version: 1.0.0
/// - since: 4.0.0
enum Modalities {
    /// Used if the application captures a bicycle ride.
    case bicycle
    /// Used if the application captures a car drive.
    case car
    /// Used if the application captures a walk.
    case walking
    /// Used if the application captures a bus ride.
    case bus
    /// Used if the application captures a train ride.
    case train

    /// The modality selected by default after the start of the Application.
    static var defaultSelection: Modalities {
        Modalities.bicycle
    }

    /// How the modality is presented in the user interface.
    var uiValue: String {
        switch self {
        case .bicycle:
            return "Bicycle"
        case .car:
            return "Car"
        case .walking:
            return "Walking"
        case .bus:
            return "Bus"
        case .train:
            return "Train"
        }
    }

    /// How the modality is presented in the data storage.
    var dbValue: String {
        switch self {
        case .car:
            return "CAR"
        case .bicycle:
            return "BICYCLE"
        case .walking:
            return "WALKING"
        case .bus:
            return "BUS"
        case .train:
            return "TRAIN"
        }
    }
}
