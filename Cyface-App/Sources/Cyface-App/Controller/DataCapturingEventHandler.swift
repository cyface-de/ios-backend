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
import DataCapturing


/// A simple protocol describing a method, that is capable of handling events from the Cyface data capturing service.
///
/// Types implementing this protocal are capable of listening to events received from the Cyface data capturing service and update themselves based on this information.
///
/// - author: Klemens Muthmann
/// - version: 1.0.0
/// - since 4.0.0
protocol CyfaceEventHandler {
    /// Handle an event from a Cyface data capturing service.
    ///
    /// Events occur for example when the service is started, paused or stopped or when new data was acquired.
    /// For further details see `DataCapturingEvent` and `DataCapturingService` in the Cyface SDK documentation.
    /// - Parameters:
    ///   - event: The event to handle.
    ///   - status: The status of the event. Erroneous events should probably discarded. If the error persists something might be wrong with your setup.
    func handle(event: DataCapturingEvent, status: Status)
}

