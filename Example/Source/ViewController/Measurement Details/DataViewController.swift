//
//  MeasurementDetailsController.swift
//  Cyface-Test
//
//  Created by Team Cyface on 27.11.17.
//  Copyright © 2017 Cyface GmbH. All rights reserved.
//

import UIKit
import DataCapturing

class DataViewController: UIViewController {
    
    // MARK: - Attributes
    var measurement: Int64?
    
    // MARK: - UIViewController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueId = segue.identifier else {
            fatalError("Trying to call segue without identifier in prepare of DataViewController!")
        }
        
        guard let measurement = self.measurement else {
            fatalError("DataViewController.prepare(for: \(segueId), sender: \(sender.debugDescription)): Unable to unwrap measurement! Has it been set yet?")
        }

        switch segueId {
        case "GeoLocationTableViewSegue":
            let geoLocationController = segue.destination as! GpsPointTableViewController
            geoLocationController.measurement = measurement
        case "AccelerationsTableViewSegue":
            let accelerationsController = segue.destination as! AccelerationPointTableViewController
            accelerationsController.measurement = measurement
        default:
            fatalError("Trying to call unknown segue \(segueId) in DataViewController#prepare")
        }

    }
}
