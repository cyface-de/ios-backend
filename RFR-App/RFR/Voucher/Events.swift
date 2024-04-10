//
//  Events.swift
//  RFR
//
//  Created by Klemens Muthmann on 10.04.24.
//
import Foundation

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
    end.hour = 0
    end.minute = 0

    return [Calendar.current.date(from: start)!...Calendar.current.date(from: end)!]
}

func thereIsCurrentEvent() -> Bool {
    return events.map { event in event.contains(Date.now) }.reduce(false) { $0 || $1}
}

func nextEvent() -> ClosedRange<Date>? {
    return events.sorted { $0.lowerBound < $1.lowerBound }.first { $0.lowerBound > Date.now}
}

let events = createEvents()
