/*
 * Copyright 2023-2024 Cyface GmbH
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
import XCTest
import OSLog
@testable import DataCapturing

final class MeasurementTest: XCTestCase {

    let NSEC_PER_SEC = 1_000_000_000

    func test() async throws {
        let oocut = MeasurementImpl() {
            return MockLocationManager()
        }
        var messages = [Message]()
        var finished = false
        let cancellable = oocut.measurementMessages.sink(receiveCompletion: { status in
            switch status {
            case .finished:
                finished = true
            case .failure(_):
                os_log("Measurement messages not finished correctly", log: OSLog.test, type: .error)
                finished = false
            }

        }) { message in
            messages.append(message)
        }

        try oocut.start()

        try await Task.sleep(nanoseconds: UInt64(2 * Double(NSEC_PER_SEC)))

        try oocut.pause()

        try await Task.sleep(nanoseconds: UInt64(2 * Double(NSEC_PER_SEC)))

        try oocut.resume()

        try await Task.sleep(nanoseconds: UInt64(2 * Double(NSEC_PER_SEC)))

        try oocut.stop()

        // TODO. There should probably be some fix and geo location events as well.
        var firstIsStarted = false
        var pausedAfterStarted = false
        var pausedIndex = 0
        var resumedAfterPaused = false
        var stopIsLast = false
        for (index, message) in messages.enumerated() {
            switch message {
            case .started(timestamp: _):
                firstIsStarted = index == 0
            case .paused(timestamp: _):
                pausedAfterStarted = index > 0
                pausedIndex = index
            case .resumed(timestamp: _):
                resumedAfterPaused = index > pausedIndex
            case .stopped(timestamp: _):
                stopIsLast = index == messages.count-1
            default:
                print(message)
            }
        }
        XCTAssertTrue(firstIsStarted)
        XCTAssertTrue(pausedAfterStarted)
        XCTAssertTrue(resumedAfterPaused)
        XCTAssertTrue(stopIsLast)
        XCTAssertTrue(finished)
    }
}
