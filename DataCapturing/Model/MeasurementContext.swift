/*
 * Copyright 2018 Cyface GmbH
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
 The context of this measurement. This is application specific and might be something like the vehicle used.

 ```
 case leisure
 case work
 case shopping
 case car
 case bike
 case motorbike
 ```
 - Todo: Make this dynamic, instead of a static enum.
 */
public enum Modality: String {
    /// The measurement was taken during leisure time.
    case leisure = "FREIZEIT"
    /// The measurement was taken while on the job or on the way to or from the job.
    case work = "ARBEIT"
    /// The measurement was taken while shopping
    case shopping = "EINKAUFEN"
    /// The measurement was taken driving a car.
    case car = "CAR"
    /// The measurement was taken riding a bicycle.
    case bike = "BICYCLE"
    /// The measurement was taken riding a motorbike.
    case motorbike = "MOTORBIKE"
}
