//
//  MeasurementDetailsViewController.swift
//  Cyface-Test
//
//  Created by Team Cyface on 29.11.17.
//  Copyright © 2017 Cyface GmbH. All rights reserved.
//

import UIKit
import DataCapturing

class MeasurementDetailsViewController: UITabBarController {

    // MARK: - Properties
    var measurement: Int64?

    // MARK: - UITabBarController

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let measurement = self.measurement else {
            fatalError("MeasurementDetailsViewController.viewDidLoad(): Measurement not yet initialized!")
        }
        
        setup(dataViewController: viewControllers?[0] as! DataViewController, withMeasurement: measurement)
        setup(mapViewController: viewControllers?[1] as! MapViewController, withMeasurement: measurement)
        setup(statisticsViewController: viewControllers?[2] as! StatisticsViewController, withMeasurement: measurement)

        let constantTitlePart = NSLocalizedString("measurementInDetailsViewTitle", comment: "Title used on the individual details view for a measurement.")
        self.title = "\(constantTitlePart) \(measurement)"
    }

    // MARK: - Methods

    private func setup(dataViewController controller: DataViewController, withMeasurement measurement: Int64) {
        controller.measurement = measurement
    }
    
    private func setup(mapViewController controller: MapViewController, withMeasurement measurement: Int64) {
        controller.measurement = measurement
    }
    
    private func setup(statisticsViewController controller: StatisticsViewController, withMeasurement measurement: Int64) {
        controller.measurement = measurement
    }
}
