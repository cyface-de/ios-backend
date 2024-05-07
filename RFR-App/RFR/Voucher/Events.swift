/*
 * Copyright 2024 Cyface GmbH
 *
 * This file is part of the Ready for Robots iOS App.
 *
 * The Ready for Robots iOS App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Ready for Robots iOS App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Ready for Robots iOS App. If not, see <http://www.gnu.org/licenses/>.
 */
import Foundation

/// Create the list of event ranges.
func createEvents() -> [ClosedRange<Date>] {
    var start = DateComponents()
    start.year = 2024
    start.month = 5
    start.day = 1
    start.timeZone = TimeZone(abbreviation: "CEST") // Japan Standard Time
    start.hour = 0
    start.minute = 0

    var end = DateComponents()
    end.year = 2024
    end.month = 5
    end.day = 31
    end.timeZone = TimeZone(abbreviation: "CEST")
    end.hour = 23
    end.minute = 59
    end.second = 59

    return [Calendar.current.date(from: start)!...Calendar.current.date(from: end)!]
}

/// `true` if there is a current event; `false`otherwise.
func thereIsCurrentEvent() -> Bool {
    return events.map { event in event.contains(Date.now) }.reduce(false) { $0 || $1}
}

/// Provide the next event range.
func nextEvent() -> ClosedRange<Date>? {
    return events.sorted { $0.lowerBound < $1.lowerBound }.first { $0.lowerBound > Date.now}
}

/// The list of events in the system.
let events = createEvents()
