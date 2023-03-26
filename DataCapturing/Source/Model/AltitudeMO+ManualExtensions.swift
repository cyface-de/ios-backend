//
//  AltitudeMO+ManualExtensions.swift
//  DataCapturing
//
//  Created by Klemens Muthmann on 07.03.23.
//

import Foundation

extension AltitudeMO: Comparable {
    public static func < (lhs: AltitudeMO, rhs: AltitudeMO) -> Bool {
        if let lhsTimestamp = lhs.timestamp, let rhsTimestamp = rhs.timestamp {
            return lhsTimestamp < rhsTimestamp
        } else {
            return lhs.objectID.hash < rhs.objectID.hash
        }
    }

    static func == (lhs: AltitudeMO, rhs: AltitudeMO) -> Bool {
        return lhs.timestamp == rhs.timestamp
    }
}
