/*
 * Copyright 2021 Cyface GmbH
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
 A delegate protocol used by the view asking for the server address. It is used to trigger model changes issued by the user.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
protocol AskForServerViewModelDelegate: AnyObject {
    /**
     Tell the model that the server address was changed by the user

     - Parameter serverAddress: The new server address to use by the app.
     */
    func change(serverAddress: String?) throws
}

/**
 The view model backing the view that asks for a new server address.

 This view is shown if the current server address is invalid, which currently means there is no address at all

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
class AskForServerViewModel: AskForServerViewModelDelegate {
    // MARK: - Exceptions
    /**
     Contains the errors/exceptions supported by the `AskForServerViewModel`

     - Author: Klemens Muthmann
     - Version: 1.0.0
     */
    enum ValidationError: Error {
        /// Thrown if an invalid URL was entered by the user
        case invalidUrl
    }
    // MARK: - Constants
    /// A regular expression used to validate URLs.
    private static let urlValidationRegex = NSRegularExpression("(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+")

    // MARK: - Properties
    /// The model backing the data used by the view model. Currently this is only the application settings.
    private let model: Settings

    // MARK: - Initializers
    /**
     Creates a new completely initialized object of this class.

     - Parameter model: The model containing the data for this view model
     */
    init(_ model: Settings) {
        self.model = model
    }

    // MARK: - AskForServerViewModelDelegate
    func change(serverAddress: String?) throws {
        debugPrint("===== Enter change =====")
        defer {
            debugPrint("===== Leave change =====")
        }
        // check for valid server address, if so add it to settings and call back to view controller
        guard let serverAddress = serverAddress else {
            return
        }

        if AskForServerViewModel.urlValidationRegex.matches(serverAddress) {
            model.serverUrl = serverAddress
        } else {
            throw ValidationError.invalidUrl
        }
    }
}

// The following code is general purpose and allows easy regex validation
extension NSRegularExpression {
    /// A convenience initializer that takes a simple pattern string and provides an `NSRegularExpression` without the requirement to catch anything.
    convenience init(_ pattern: String) {
        do {
            try self.init(pattern: pattern)
        } catch {
            preconditionFailure("Illegal regular expression: \(pattern).")
        }
    }

    /**
     A convenience method wrapping the intricate code that decides whether a regular expression matches into an easy interface just taking a `String` as input and providing a boolean output.

     - Parameter string: The `String` to match against the regular expression
     - Returns: `true` if the regular expression matches the `String` completely; `false` otherwise
     */
    func matches(_ string: String) -> Bool {
        let range = NSRange(location: 0, length: string.utf16.count)
        return firstMatch(in: string, options: [], range: range) != nil
    }
}
