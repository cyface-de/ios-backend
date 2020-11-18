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
            fatalError("Unable to unwrap measurement! Has it been set yet?")
        }

        switch segueId {
        case "GeoLocationTableViewSegue":
            guard let geoLocationController = segue.destination as? GpsPointTableViewController else {
                fatalError()
            }
            geoLocationController.measurement = measurement
        case "AccelerationsTableViewSegue":
            guard let accelerationsController = segue.destination as? AccelerationPointTableViewController else {
                fatalError()
            }
            accelerationsController.measurement = measurement
        default:
            fatalError("Trying to call unknown segue \(segueId) in DataViewController#prepare")
        }

    }
}
