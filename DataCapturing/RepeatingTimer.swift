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
 A repeating timer implementation, that makes sure that calling resume and suspend on a timer is balanced.

 This implementation is based on a <a href="https://medium.com/over-engineering/a-background-repeating-timer-in-swift-412cecfd2ef9">post from medium</a>.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 4.0.0
 */
class RepeatingTimer {

    /// The time interval between calls to the timer.
    let timeInterval: TimeInterval

    /**
     Creates a new completely initialized instance of this class

     - Parameter timeInterval: The time interval between calls to the timer.
     */
    init(timeInterval: TimeInterval) {
        self.timeInterval = timeInterval
    }

    /// The actual timer, which is wrapped by an instance of this class.
    private lazy var timer: DispatchSourceTimer = {
        let internalTimer = DispatchSource.makeTimerSource()
        internalTimer.schedule(deadline: .now() + self.timeInterval, repeating: self.timeInterval)
        internalTimer.setEventHandler(handler: { [weak self] in
            self?.eventHandler?()
        })
        return internalTimer
    }()

    /// Handler to call on each invocation of this timer.
    var eventHandler: (() -> Void)?

    /**
     Enumeration listing all possible timer states.

     ```
     case suspended
     case resumed
     ```
     */
    private enum State {
        /// The state assumed by suspended timers.
        case suspended
        /// The state assumed by running timers.
        case resumed
    }

    /// The current state of the timer, which is used to balance suspend and resume calls.
    private var state: State = .suspended

    /// Makes sure the timer is properly shut down.
    deinit {
        timer.setEventHandler {}
        timer.cancel()
        /*
         If the timer is suspended, calling cancel without resuming
         triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
         */
        resume()
        eventHandler = nil
    }

    /// Resumes the timer if suspended. Does nothing if already running.
    func resume() {
        if state == .resumed {
            return
        }
        state = .resumed
        timer.resume()
    }

    /// Suspends the timer if running. Does nothing if already suspended.
    func suspend() {
        if state == .suspended {
            return
        }
        state = .suspended
        timer.suspend()
    }
}
