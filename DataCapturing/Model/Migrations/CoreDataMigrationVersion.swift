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
 This is an enumeration of all version of the Cyface iOS data model used as part of the SDK.
 It is required to start migrations between the different versions.

 - Author: Klemens Muthmann
 - Version: 1.2.0
 - Since: 4.0.0
 */
public enum CoreDataMigrationVersion: String, CaseIterable {
    /// The first and oldest version of the model.
    case version1 = "CyfaceModel"
    /// The second version of the model.
    case version2 = "2"
    /// The third version of the model.
    case version3 = "3"
    /// The fourth version of the model.
    case version4 = "4"
    /// The fifth version of the model.
    case version5 = "5"
    /// The sixth version of the model.
    case version6 = "6"
    /// The seventh version of the model.
    case version7 = "7"

    // MARK: - Current

    /// The currently used model version.
    static var current: CoreDataMigrationVersion {
        guard let current = allCases.last else {
            fatalError("No model versions found")
        }

        return current
    }

    // MARK: - Migration

    /// Provides the following version for each supported model version.
    func nextVersion() -> CoreDataMigrationVersion? {
        switch self {
        case .version1:
            return .version2
        case .version2:
            return .version3
        case .version3:
            return .version4
        case .version4:
            return .version5
        case .version5:
            return .version6
        case .version6:
            return .version7
        case .version7:
            return nil
        }
    }
}
