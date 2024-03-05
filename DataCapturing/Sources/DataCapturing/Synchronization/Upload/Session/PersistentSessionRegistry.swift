/*
 * Copyright 2024 Cyface GmbH
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
 A ``SessionRegistry`` capable of keeping sessions between application restarts, by storing them to a persistent storage.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
public struct PersistentSessionRegistry: SessionRegistry {
    // MARK: - Properties
    let dataStoreStack: DataStoreStack
    let uploadFactory: UploadFactory

    // MARK: - Methods
    public mutating func get(measurement: FinishedMeasurement) throws -> (any Upload)? {
        return nil
    }

    public mutating func register(upload: any Upload) throws {
        /*dataStoreStack.wrapInContext { context in
            let uploadSession = UploadSession(context: context)

            try context.save()
        }*/
    }
    
    public mutating func remove(upload: any Upload) {
        
    }
}
