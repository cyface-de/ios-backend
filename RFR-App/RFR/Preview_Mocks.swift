/*
 * Copyright 2023-2024 Cyface GmbH
 *
 * This file is part of the Ready for Robots App.
 *
 * The Ready for Robots App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Ready for Robots App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Ready for Robots App. If not, see <http://www.gnu.org/licenses/>.
 */
#if DEBUG
import Foundation
import DataCapturing
import CoreData
import OSLog

/**
 An authenticator that does not communicate with any server and only provides a fake authentication token.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.2.2
 */
class MockAuthenticator: Authenticator {
    func authenticate(onSuccess: @escaping (String) -> Void, onFailure: @escaping (Error) -> Void) {
        onSuccess("fake-token")
    }

    func authenticate() async throws -> String {
        return "test"
    }

    func delete() async throws {
        print("Deleting User")
    }

    func logout() async throws {
         print("Logout")
    }

    func callback(url: URL) {
        print("Called back")
    }
}

/**
 A ``DataStoreStack`` not accessing any data store.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.2.2
 */
class MockDataStoreStack: DataStoreStack {

    init() {
        // Nothing to do here.
    }

    func wrapInContextReturn<T>(_ block: (NSManagedObjectContext) throws -> T) throws -> T {
        return try block(NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType))
    }

    private var nextIdentifier = UInt64(0)

    func nextValidIdentifier() throws -> UInt64 {
        nextIdentifier += 1
        return nextIdentifier
    }

    func wrapInContext(_ block: (NSManagedObjectContext) throws -> Void) throws {
        try block(NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType))
    }

    func setup() async throws {
        // Nothing to do here!
    }
}

/**
 A mock for the vouchers interface avoiding actual network communication.

 This should be used during testing and for previews.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 3.2.2
 */
struct MockVouchers: Vouchers {
    /// The amount of simulated vouchers available.
    var count: Int
    /// The voucher currently enabled for the active user.
    let voucher: Voucher

    /// Simulate requesting a voucher from the server. This will always return the hard coded voucher provided on initialization.
    func requestVoucher() async throws -> Voucher {
        return voucher
    }
}

#endif
