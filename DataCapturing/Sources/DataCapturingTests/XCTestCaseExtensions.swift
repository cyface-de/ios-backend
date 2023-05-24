//
//  File.swift
//  
//
//  Created by Klemens Muthmann on 03.01.23.
//

import Foundation
import XCTest
@testable import DataCapturing

extension XCTestCase {
    public static func testBundle() -> Bundle? {
        return Bundle.module
    }

    public static func appBundle() -> Bundle? {
        let mainBundle = Bundle(for: CoreDataStack.self)
        let appBundle = Bundle(url: mainBundle.bundleURL.appendingPathComponent("DataCapturing_DataCapturing.bundle"))
        return appBundle
    }
}
