/*
 * Copyright 2017-2022 Cyface GmbH
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
import CoreData

extension TrackMO {
    /**
     The altitudes in this measurement already cast to the correct type.
     */
    public func typedAltitudes() -> [AltitudeMO] {
        guard let typedAltitudes = altitudes?.array as? [AltitudeMO] else {
            fatalError("Unable to cast altitudes to the correct type!")
        }

        return typedAltitudes
    }

    /**
     The locations from this measurement already cast to the correct type.
     */
    public func typedLocations() -> [GeoLocationMO] {
        guard let typedLocations = locations?.array as? [GeoLocationMO] else {
            fatalError("Unable to cast altitudes to the correct type!")
        }

        return typedLocations
    }
}
