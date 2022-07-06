//
//  Modalities.swift
//  Cyface-App
//
//  Created by Klemens Muthmann on 28.04.22.
//

import Foundation

enum Modalities {
    case bicycle
    case car
    case walking
    case bus
    case train

    static var defaultSelection: Modalities {
        Modalities.bicycle
    }

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
