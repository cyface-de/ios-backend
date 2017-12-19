//
//  DataCapturingListener.swift
//  DataCapturingServices
//
//  Created by Team Cyface on 02.11.17.
//  Copyright © 2017 Cyface GmbH. All rights reserved.
//

/**
 This protocol defines how to listen for data capturing events.
 
 - Author:
 Klemens Muthmann
 
 - Version:
 1.0.0
 
 - Since
 1.0.0
 
 An instance of a class implementing this protocol should register with a `DataCapturingService` via the method `DataCapturingService.startCapturing(Listener:DataCapturingListener)`.
 */
public protocol DataCapturingListener {
    /*/**
     Called everytime the capturing service received a geo location fix and thus is able to track its position.
     */
    func onGpsFixAcquire()
    /**
     Called everytime the capturing service loses its geo location fix.
     */
    func onGpsFixLost()
    /**
     This method is called eacht time the `DataCapturingService`receives a new geo location position.
     - parameters:
     - position: The new geo location position.
     */
    func onNewGpsPositionAcquired(position:GeoLocationMO)
    /**
     This method is called each time the application runs out of space. How much space is used and how much is available may be retrieved from `allocation`.
     -parameters:
     - allocation: Information about the applications disk (or rather SD card) space consumption.
     */
    func onLowDiskSpace(allocation:DiskConsumption)
    /**
     Invoked each time the `DataCapturingService requires some pemission from the iOS system. That way it is possible to show the user some explanation as to why that permission is required.
     */
    func onRequire(permission:String,for reason : Reason) -> Bool
    /**
     Invoked if the service has synchronized all pending cached data successfully and delted the local copies.
     */
    func onSynchronizationSuccessful()*/
}
