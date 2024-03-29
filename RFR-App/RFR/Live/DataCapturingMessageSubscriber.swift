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
 * The Ready for Robots App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Ready for Robots App. If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation
import Combine
import DataCapturing

/**
 Base protocol for all parties interested in receiving ``Message`` objects from the *Cyface* ``Measurement``, during data capturing.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.1.2
 */
protocol DataCapturingMessageSubscriber {
    func subscribe(to messages: some Publisher<Message, Never>)
}
