//
// Copyright (C) 2018 - 2020 Cyface GmbH - All Rights Reserved
// Unauthorized copying of this file, via any medium is strictly prohibited
// Proprietary and confidential
//

import Foundation

/**
 An enumeration for all the possible status variants a measurement can be in.

 - Author: Klemens Muthmann
 - Since: 3.1.0
 - Version 1.0.0
 */
enum MeasurementCellStatus {
    /// The measurement is not synchronized yet and was not tried.
    case unsynchronized
    /// The measurement is currently synchronizing with the Cyface server.
    case uploading
    /// The measurement upload has failed previously.
    case uploadFailed
    /// The measurement was successfully synchronized.
    case uploadSuccessful
}
