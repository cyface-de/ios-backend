//
//  Measurement.swift
//  DataCapturingServices
//
//  Created by Team Cyface on 02.11.17.
//  Copyright © 2017 Cyface GmbH. All rights reserved.
//

import Foundation

/**
 An object of this class represents a single measurement captured by the `DataCapturingService`.
 
 - Author:
 Klemens Muthmann
 
 - Version:
 1.0.0
 
 - Since:
 1.0.0
 
 This usually happens between complementary calls to `DataCapturingService#startCapturing()` and `DataCapturingService#stopCapturing()`.
 */
public class Measurement : Equatable {
    //MARK: Properties
    /**
     The system wide unique identifier of this measurement. Usually this value is generated by a data store (i.e. database).
     */
    public var id : Int64?
    
    private (set) public var accelerations = [AccelerationPoint]()
    
    private (set) public var geoLocations = [GeoLocation]()
    
    //MARK: Initializers
    public init(_ id : Int64?) {
        self.id = id
    }
    
    //MARK: Methods
    func append(_ acceleration: AccelerationPoint) {
        accelerations.append(acceleration)
    }
    
    func append(_ geoLocation: GeoLocation) {
        geoLocations.append(geoLocation)
    }
    
    //MARK: Equatable
    public static func ==(lhs: Measurement, rhs: Measurement) -> Bool {
        return lhs.id == rhs.id
    }
}
