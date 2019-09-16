/*
 * Copyright 2019 Cyface GmbH
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

/**
 Provides a listing of all the events, that might occur during a data capturing run. These events are saved with a timestamp of their occurrence, to reconstruct them for later use.

 - Author: Klemens Muthmann
 - Version: 1.1.0
 - Since: 4.6.1
 */
public enum EventType: Int16 {
    case lifecycleStart
    case lifecyclePause
    case lifecycleResume
    case lifecycleStop
    case modalityTypeChange
}
