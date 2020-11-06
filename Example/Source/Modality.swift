//
// Copyright (C) 2018 - 2020 Cyface GmbH - All Rights Reserved
// Unauthorized copying of this file, via any medium is strictly prohibited
// Proprietary and confidential
//

import Foundation

/**
 A class describing the differen modes of transportation available for capturing measurements.

 This class defines the transportation modes used by the Cyface app and creates a mapping between database identifier and representation inside the user interface for each modality.

 This is not an enumeration intentionally.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.0
 */
public class Modality {
    /// The transportation mode used, when a car was used for transportation.
    public static let car = Modality(dbValue: "CAR", uiString: NSLocalizedString("car", comment: "Transportation mode using cars"))
    /// The transporation mode used, when a bicycle was used for transportation.
    public static let bike = Modality(dbValue: "BICYCLE", uiString: NSLocalizedString("bicycle", comment: "Transportation mode using bicycles"))
    /// The transportation mode used when a measurement was captured while walking.
    public static let walking = Modality(dbValue: "WALKING", uiString: NSLocalizedString("walking", comment: "Transportation mode where the user is walking"))
    /// The transportation mode used, when a bus was used for transportation.
    public static let bus = Modality(dbValue: "BUS", uiString: NSLocalizedString("bus", comment: "Transportation mode using the bus"))
    /// The transportation mode used, when a train was used for transportation.
    public static let train = Modality(dbValue: "TRAIN", uiString: NSLocalizedString("train", comment: "Transportation mode using trains"))

    /// The database value used to store this transportation mode within the application database.
    public let dbValue: String
    /// The text representation used to display this transportation mode on user interface elements
    public let uiString: String

    /**
     Creates a new completely initialized `Modality`.

     This constructor should be used to create new unknown `Modality` instances and should be unnecessary within this application. Use the factory method `Modality.from(:String)` instead.

     - Parameters:
            - dbValue: The database value used to store this transportation mode within the application database
            - uiString: The text representation used to display this transportation mode on user interface elements
     */
    private init(dbValue: String, uiString: String) {
        self.dbValue = dbValue
        self.uiString = uiString
    }

    /**
     Creates the correct  `Modality` from a database value.

     - Parameter dbValue: The database value to create the modality from.
     */
    public static func from(dbValue: String) -> Modality {
        switch dbValue {
        case car.dbValue:
            return car
        case bike.dbValue:
            return bike
        case walking.dbValue:
            return walking
        case bus.dbValue:
            return bus
        case train.dbValue:
            return train
        default:
            fatalError("Unsupported transporation mode \(dbValue)!")
        }
    }
}
