//
//  CoreDataMigrationVersion.swift
//  DataCapturing
//
//  Created by Team Cyface on 27.03.19.
//  Copyright © 2019 Cyface GmbH. All rights reserved.
//

import Foundation

enum CoreDataMigrationVersion: String, CaseIterable {
    case version1 = "CyfaceModel"
    case version2 = "2"
    case version3 = "3"
    case version4 = "4"

    // MARK: - Current

    static var current: CoreDataMigrationVersion {
        guard let current = allCases.last else {
            fatalError("No model versions found")
        }

        return current
    }

    // MARK: - Migration

    func nextVersion() -> CoreDataMigrationVersion? {
        switch self {
        case .version1:
            return .version2
        case .version2:
            return .version3
        case .version3:
            return .version4
        case .version4:
            return nil
        }
    }
}
