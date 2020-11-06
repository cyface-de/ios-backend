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
 The status returned by asynchronous callback handlers.

 This tells the caller, whether an asynchronous call has been successful or not and if not it provides further information about the `Error`. This is required, since an asynchronous call can not throw an `Error` to the calling thread.

 ```
 case success
 case error(Error)
 ```

 - Author: Klemens Muthmann
 - Version: 1.0.1
 - Since: 2.2.0
 */
@available(swift, deprecated: 5.0.0, message: "There is a better solution provide by Swift natively beginning with Swift 5")
public enum Status {
    /// The status returned if an asynchronous callback has finished successfully.
    case success
    /// The status returned if an asynchronous callback has finished with an error. Details about the error are available via the `Error` parameter.
    case error(Error)
}
