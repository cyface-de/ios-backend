//
//  DiskConsumption.swift
//  DataCapturingServices
//
//  Created by Team Cyface on 03.11.17.
//  Copyright © 2017 Cyface GmbH. All rights reserved.
//

import Foundation

/**
 Objects of this class represent the current disk (or rather SD card) space used and available.
 
 - Author:
 Klemens Muthmann
 
 - Version:
 1.0.0
 
 - Since:
 1.0.0
 
 This space is mostly filled with unsynchronized `Measurement`s. To avoid filling up the users SD card it is advisable to delte `Measurement`s as soon as they use up too much space.
 */
public class DiskConsumption {
    /**
     The amount of bytes currently used by the `DataCapturingService`.
     */
    public let consumedBytes : Int
    /**
     The amount of bytes still available for the `DataCapturingService`.
     */
    public let availableBytes : Int
    
    /**
     Creates a new completely initialized `DiskConsumption` object.
     
     - parameters:
     - consumedBytes: The amount of bytes currently used by the `DataCapturingService`.
     - availableBytes: The amount of bytes still available for the `DataCapturingService`.
     */
    public init(consumedBytes : Int, availableBytes : Int) {
        guard consumedBytes>=0 else {
            fatalError("Illegal value for consumed bytes. May not be smaller then 0 but was \(consumedBytes)")
        }
        guard availableBytes>=0 else {
            fatalError("Illegal value for available bytes. May not be smaller then 0 but was \(availableBytes)")
        }
        
        self.consumedBytes = consumedBytes
        self.availableBytes = availableBytes
    }
}
